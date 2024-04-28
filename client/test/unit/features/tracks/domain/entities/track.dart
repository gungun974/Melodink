import 'package:faker/faker.dart';
import 'package:melodink_client/features/tracks/domain/entities/track.dart';

Track getRandomTrack() {
  var faker = Faker();

  return Track(
    id: faker.randomGenerator.integer(1000, min: 1),
    title: faker.lorem.words(3).join(" "),
    album: faker.lorem.words(2).join(" "),
    duration: Duration(seconds: faker.randomGenerator.integer(300, min: 1)),
    cacheFile: null,
    tagsFormat: 'flac',
    fileType: 'flac',
    path: '/music/${faker.lorem.word()}.flac',
    fileSignature: faker.guid.guid(),
    metadata: getRandomTrackMetadata(),
    dateAdded: faker.date.dateTime(minYear: 2010, maxYear: 2022),
  );
}

TrackMetadata getRandomTrackMetadata() {
  final totalDiscs = faker.randomGenerator.integer(2, min: 1);
  final totalTracks = faker.randomGenerator.integer(8, min: 1);
  final date = faker.date.dateTime(minYear: 1990, maxYear: 2020);

  return TrackMetadata(
    trackNumber: faker.randomGenerator.integer(totalTracks, min: 1),
    totalTracks: totalTracks,
    discNumber: faker.randomGenerator.integer(totalDiscs, min: 1),
    totalDiscs: totalDiscs,
    date: date.toString(),
    year: date.year,
    genre: faker.lorem.word(),
    lyrics: "",
    comment: faker.lorem.sentences(3).join(' '),
    acoustID: faker.lorem.words(4).join('_'),
    acoustIDFingerprint: faker.lorem.words(10).join('_'),
    artist: faker.person.name(),
    albumArtist: faker.person.name(),
    composer: faker.person.name(),
    copyright: date.year.toString(),
  );
}
