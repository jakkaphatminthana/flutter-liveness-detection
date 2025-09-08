import 'package:flutter/material.dart';

class FaceLivenessDashbord extends StatelessWidget {
  final double? smilingProbability;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  final double? headEulerAngleY;
  final bool waitingForNeutral;
  final bool isFaceInFrame;
  final int currentActionIndex;
  final int livenessActionsTotal;

  const FaceLivenessDashbord({
    super.key,
    required this.smilingProbability,
    required this.leftEyeOpenProbability,
    required this.rightEyeOpenProbability,
    required this.headEulerAngleY,
    required this.waitingForNeutral,
    required this.isFaceInFrame,
    required this.currentActionIndex,
    required this.livenessActionsTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.yellow, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DEV MODE',
            style: TextStyle(
              color: Colors.yellow,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Smile: ${smilingProbability != null ? (smilingProbability! * 100).toStringAsFixed(2) : 'N/A'}%',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          Text(
            'Eyes: ${leftEyeOpenProbability != null && rightEyeOpenProbability != null ? (((leftEyeOpenProbability! + rightEyeOpenProbability!) / 2) * 100).toStringAsFixed(2) : 'N/A'}%',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          Text(
            'Head: ${headEulerAngleY != null ? headEulerAngleY!.toStringAsFixed(2) : 'N/A'}°',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          Text(
            'Frame: ${waitingForNeutral ? 'PASSED' : (isFaceInFrame ? 'IN' : 'OUT')}',
            style: TextStyle(
              color: waitingForNeutral
                  ? Colors.green
                  : (isFaceInFrame ? Colors.white : Colors.red),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          Text(
            'Step: ${currentActionIndex + 1}/$livenessActionsTotal',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
