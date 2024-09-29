package scanner

import (
	"bytes"
	"compress/gzip"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/pkgs/audiolength"

	"github.com/go-fingerprint/fingerprint"
	"github.com/go-fingerprint/gochroma"

	"github.com/go-resty/resty/v2"
)

const ACOUSTID_CLIENT_ID = "YpyZARNugs"

func NewAcoustIdScanner() AcoustIdScanner {
	client := resty.New()

	client.
		SetRetryCount(5).
		SetRetryWaitTime(3 * time.Second).
		SetRetryMaxWaitTime(30 * time.Second).
		AddRetryCondition(
			func(r *resty.Response, err error) bool {
				return r.StatusCode() >= 500 || err != nil
			})

	return AcoustIdScanner{
		client: client,
		mutex:  sync.Mutex{},
	}
}

type AcoustIdScanner struct {
	client *resty.Client
	mutex  sync.Mutex
}

type AcoustIdRelease struct {
	Id    string `json:"id"`
	Title string `json:"title"`
}

type AcoustIdRecording struct {
	Id       string            `json:"id"`
	Releases []AcoustIdRelease `json:"releases"`
}

type AcoustIdResult struct {
	Id         string              `json:"id"`
	Recordings []AcoustIdRecording `json:"recordings"`
	Score      float64             `json:"score"`
}

type AcoustIdResponse struct {
	Results []AcoustIdResult `json:"results"`
	Status  string           `json:"status"`
}

var AcoustIdNotFoundError = errors.New("AcoustId is not found")

func (s *AcoustIdScanner) ScanAcoustIdFingerprint(path string) (string, error) {
	var inputSamples io.Reader

	ffmpeg := exec.Command("ffmpeg", "-v", "quiet",
		"-i", path, "-f", "s16le", "-ac", "1", "-c:a", "pcm_s16le", "-ar", "44100", "pipe:1")
	var err error
	ffmpegOut, err := ffmpeg.StdoutPipe()
	ffmpeg.Stderr = os.Stderr
	if err != nil {
		logger.ScannerLogger.Errorf(
			"Unable to spin up ffmpeg to decode %v", err,
		)
		return "", err
	}
	err = ffmpeg.Start()
	if err != nil {
		logger.ScannerLogger.Errorf(
			"Unable to spin up ffmpeg to decode %v", err,
		)
		return "", err
	}

	alldata, _ := io.ReadAll(ffmpegOut)
	inputSamples = bytes.NewReader(alldata)

	defer ffmpeg.Process.Wait()
	defer ffmpeg.Process.Kill()

	fpcalc := gochroma.New(gochroma.AlgorithmDefault)
	defer fpcalc.Close()

	fpoptions := fingerprint.RawInfo{
		Src:        inputSamples,
		Channels:   1,
		Rate:       44100,
		MaxSeconds: uint((2 * time.Minute).Seconds()),
	}

	acoustIdFingerprint, err := fpcalc.Fingerprint(fpoptions)
	if err != nil {
		logger.ScannerLogger.Errorf(
			"Unable to fingerprint %v", err,
		)
		return "", err
	}

	return acoustIdFingerprint, nil
}

func (s *AcoustIdScanner) ScanAcoustId(path string) (AcoustIdResponse, error) {
	acoustIdFingerprint, err := s.ScanAcoustIdFingerprint(path)
	if err != nil {
		return AcoustIdResponse{}, err
	}

	duration, _ := audiolength.GetAudioDuration(path)

	params := url.Values{}
	params.Add("client", ACOUSTID_CLIENT_ID)
	params.Add("meta", "recordingids+releases+compress")
	params.Add(
		"duration",
		strconv.Itoa(int((time.Duration(duration) * time.Millisecond).Seconds())),
	)
	params.Add(
		"fingerprint",
		acoustIdFingerprint,
	)

	var buf bytes.Buffer
	gzipWriter := gzip.NewWriter(&buf)
	_, err = gzipWriter.Write([]byte(strings.ReplaceAll(params.Encode(), "%2B", "+")))
	if err != nil {
		return AcoustIdResponse{}, err
	}
	err = gzipWriter.Close()
	if err != nil {
		return AcoustIdResponse{}, err
	}

	s.mutex.Lock()

	logger.ScannerLogger.Infof("Perform an acoustid lookup for %s", path)

	resp, err := s.client.R().
		SetHeader("Content-Encoding", "gzip").
		SetHeader("Content-Type", "application/x-www-form-urlencoded").
		SetBody(&buf).
		Post("https://api.acoustid.org/v2/lookup")
	if err != nil {
		time.Sleep(time.Millisecond * 1100)
		s.mutex.Unlock()

		return AcoustIdResponse{}, err
	}

	time.Sleep(time.Millisecond * 1100)
	s.mutex.Unlock()

	if resp.StatusCode() == http.StatusNotFound {
		return AcoustIdResponse{}, AcoustIdNotFoundError
	}

	if resp.StatusCode() != http.StatusOK {
		logger.ScannerLogger.Errorf(
			"Unable to get acoustid response %v", resp,
		)
		return AcoustIdResponse{}, errors.New("Unable to get acoustid response")
	}

	var apiResponse AcoustIdResponse

	err = json.Unmarshal(resp.Body(), &apiResponse)
	if err != nil {
		logger.ScannerLogger.Errorf(
			"Failed to parse acoustid response %v", err,
		)
		return AcoustIdResponse{}, err
	}

	for _, result := range apiResponse.Results {
		for j := len(result.Recordings) - 1; j >= 0; j-- {
			if len(result.Recordings[j].Releases) == 0 {
				result.Recordings = append(result.Recordings[:j], result.Recordings[j+1:]...)
			}
		}
	}

	for i := len(apiResponse.Results) - 1; i >= 0; i-- {
		if len(apiResponse.Results[i].Recordings) == 0 {
			apiResponse.Results = append(apiResponse.Results[:i], apiResponse.Results[i+1:]...)
		}
	}

	if len(apiResponse.Results) == 0 {
		return AcoustIdResponse{}, AcoustIdNotFoundError
	}

	return apiResponse, nil
}
