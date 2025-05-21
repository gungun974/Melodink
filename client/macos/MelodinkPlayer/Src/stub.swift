import MelodinkPlayer

public class FakeMelodinkPlayer {
  public func dummyMethodToEnforceBundling() {
    // dummy calls to prevent tree shaking
    mi_player_init();
  }
}
