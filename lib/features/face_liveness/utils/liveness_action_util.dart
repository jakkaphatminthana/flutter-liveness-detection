enum LivenessAction { smile, blink, lookRight, lookLeft, lookStraight }

extension LivenessActionUtil on LivenessAction {
  static List<String> toList() {
    return LivenessAction.values.map((e) => e.name).toList();
  }

  String get name => toString().split('.').last;

  String get label {
    return switch (this) {
      LivenessAction.smile => 'Smile',
      LivenessAction.blink => 'Blink',
      LivenessAction.lookRight => 'Look Right',
      LivenessAction.lookLeft => 'Look Left',
      LivenessAction.lookStraight => 'Look Straight',
    };
  }

  static String getActionLabel(LivenessAction? action) {
    return action?.label ?? 'Move your face into the frame';
  }
}
