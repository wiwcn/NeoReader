enum PlayMode {
  sequential,
  listLoop,
  single,
  shuffle,
}

extension PlayModeX on PlayMode {
  PlayMode get next {
    const values = PlayMode.values;
    return values[(index + 1) % values.length];
  }

  String labelZh() {
    switch (this) {
      case PlayMode.sequential:
        return '顺序';
      case PlayMode.listLoop:
        return '列表循环';
      case PlayMode.single:
        return '单曲循环';
      case PlayMode.shuffle:
        return '随机';
    }
  }

  String labelEn() {
    switch (this) {
      case PlayMode.sequential:
        return 'Sequential';
      case PlayMode.listLoop:
        return 'List loop';
      case PlayMode.single:
        return 'Single';
      case PlayMode.shuffle:
        return 'Shuffle';
    }
  }
}
