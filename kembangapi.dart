import 'dart:io';
import 'dart:async';
import 'dart:math';

void main() async {
  // Clear the screen at the start
  clearScreen();

  // Ask user for the number of fireworks to launch
  print("How many fireworks do you want to launch?");
  String? input = stdin.readLineSync();
  int fireworkCount = int.tryParse(input ?? '0') ?? 0;

  // Fixed starting position for the first firework
  int startX = stdout.terminalColumns ~/ 2; // Middle of the terminal
  int endY = stdout.terminalLines - 1; // Bottom of the terminal

  // Launch the first firework from the center
  var fireworkColors = getColorForFirework(0); // Get colors for the first firework
  String fireworkColor = fireworkColors['foreground']!;
  String backgroundColor = fireworkColors['background']!;
  fillScreenWithBackground(backgroundColor);
  await fireworkAnimation(fireworkColor, startX, endY, backgroundColor);
  await Future.delayed(Duration(milliseconds: 500));  // Delay before next firework

  // Loop to launch the remaining specified number of fireworks
  for (int i = 1; i < fireworkCount; i++) {
    fireworkColors = getColorForFirework(i); // Get colors for subsequent fireworks
    fireworkColor = fireworkColors['foreground']!;
    backgroundColor = fireworkColors['background']!;

    // Randomize start position for subsequent fireworks
    startX = Random().nextInt(stdout.terminalColumns);

    fillScreenWithBackground(backgroundColor);
    await fireworkAnimation(fireworkColor, startX, endY, backgroundColor);
    await Future.delayed(Duration(milliseconds: 500));  // Delay between fireworks
  }

  // Clear the screen after the firework show
  clearScreen();

  // Now animate the message after the fireworks
  await animateMessage();
}

// Function to animate the message
Future<void> animateMessage() async {
  // Message to be animated
  String message = '''
*       *    *********      **********                    *           **        *      *******        **
*       *    *         *    *         *                  * *          * *       *     *       *       **
*       *    *          *   *          *                *   *         *  *      *    *         *      **
*       *    *         *    *           *              *     *        *   *     *    *         *      **
*********    **********     *           *             *       *       *    *    *    *         *      **
*       *    *         *    *           *            ***********      *     *   *    *         *      **
*       *    *          *   *          *            *           *     *      *  *     *       *       **
*       *    *         *    *         *            *             *    *       * *      *     *
*       *    **********     **********            *               *   *        **       *****         **
''';

  // Set assumed console width and calculate padding for centering
  int consoleWidth = 150; // You can adjust this based on your terminal width
  int messageWidth = 104; // Width of the longest line in the message
  int padding = ((consoleWidth - messageWidth) / 2).floor();

  String paddedMessage = message
      .split('\n')
      .map((line) => ' ' * padding + line)
      .join('\n');

  // Total number of steps for animation (number of rows the text will move up)
  int steps = 15;

  // Extra space below the message to simulate starting off-screen
  int offscreenPadding = 10;

  // Animate the message starting from off-screen and moving upwards
  for (int i = steps + offscreenPadding; i >= 0; i--) {
    // Clear screen at each step
    clearScreen();

    // Print empty lines before the message to simulate upward movement from off-screen
    for (int j = 0; j < i; j++) {
      print('');
    }

    // Print the padded message centered in the middle
    print(paddedMessage);

    // Slow down the animation by adding a delay
    await Future.delayed(Duration(milliseconds: 300));
  }
}

// Function to clear the console screen
void clearScreen() {
  // Using ANSI escape codes to clear the screen properly
  stdout.write("\x1B[2J\x1B[0;0H");
}

void fillScreenWithBackground(String backgroundColor) {
  final int width = stdout.terminalColumns;
  final int height = stdout.terminalLines;

  // Print spaces with the background color across the entire terminal
  for (int y = 0; y < height; y++) {
    stdout.write("\x1B[${y};0H$backgroundColor${' ' * width}\x1B[0m");
  }
}

Future<void> fireworkAnimation(String color, int startX, int endY, String backgroundColor) async {
  final int height = stdout.terminalLines;
  const int launchSpeed = 100; // Delay between each step of the firework's launch

  // Start fading the trail while the firework is animating
  fadeTrail(startX, endY, launchSpeed, backgroundColor);

  // Firework launch
  for (int y = endY; y >= (height ~/ 2); y--) {
    await drawFirework(startX, y, '*', color);
    await Future.delayed(Duration(milliseconds: launchSpeed));
  }

  // Firework explosion
  await explode(startX, (height ~/ 2), color, backgroundColor);  // Pass backgroundColor to explosion
}

Future<void> drawFirework(int x, int y, String symbol, String color) async {
  // Print the firework symbol at a specific position without clearing the background
  stdout.write("\x1B[${y};${x}H$color$symbol\x1B[0m");  // Print with foreground color and no background
}

Future<void> explode(int x, int y, String color, String backgroundColor) async {
  final List<List<int>> explosionPattern = [
    [0, 0], // Center of the explosion
    [-1, -1], [-1, 0], [-1, 1],
    [0, -1], [0, 1],
    [1, -1], [1, 0], [1, 1]
  ];

  // Draw the explosion symbols
  for (int i = 0; i < 3; i++) {
    for (final offset in explosionPattern) {
      int drawX = x + offset[1] * (i + 1);
      int drawY = y + offset[0] * (i + 1);
      drawFirework(drawX, drawY, '*', color);  // Draw firework without clearing the background
    }
    await Future.delayed(Duration(milliseconds: 200));
  }

  // Now fade out the explosion starting from the center
  await fadeOutExplosion(x, y, explosionPattern, backgroundColor);
}

// Function to fade out the explosion symbols starting from the center
Future<void> fadeOutExplosion(int x, int y, List<List<int>> explosionPattern, String backgroundColor) async {
  const int fadeSteps = 5; // Number of fade steps for the explosion

  // Fade out the explosion symbols
  for (int step = 0; step < fadeSteps; step++) {
    await Future.delayed(Duration(milliseconds: 100)); // Delay between fade steps

    // Start clearing from the center of the explosion
    for (final offset in explosionPattern) {
      int drawX = x + offset[1] * (step + 1);
      int drawY = y + offset[0] * (step + 1);
      // Clear by printing a space with background color
      stdout.write("\x1B[${drawY};${drawX}H$backgroundColor \x1B[0m");
    }
  }
}

// Function to clear the trail gradually from the bottom of the screen
void fadeTrail(int x, int startY, int launchSpeed, String backgroundColor) async {
  const int trailLength = 13; // Length of the trail

  // Draw the trail initially with a shorter delay
  for (int i = 0; i < trailLength; i++) {
    int y = startY - i;
    if (y > 0) {
      stdout.write("\x1B[${y};${x}H*\x1B[0m");
      await Future.delayed(Duration(milliseconds: launchSpeed)); // Match the firework launch speed
    }
  }

  // Now fade out the trail from the bottom to the top with a shorter delay
  for (int i = 0; i < trailLength; i++) {
    int y = startY - i;
    if (y > 0) {
      await Future.delayed(Duration(milliseconds: launchSpeed)); // Match the firework launch speed
      stdout.write("\x1B[${y};${x}H$backgroundColor \x1B[0m"); // Clear by printing a space with background color
    }
  }
}

// Function to alternate colors for each firework instance (foreground and background)
Map<String, String> getColorForFirework(int index) {
  List<Map<String, String>> colors = [
    {'foreground': '\x1B[31m', 'background': '\x1B[41m'},  // Red
    {'foreground': '\x1B[32m', 'background': '\x1B[42m'},  // Green
    {'foreground': '\x1B[33m', 'background': '\x1B[43m'},  // Yellow
    {'foreground': '\x1B[34m', 'background': '\x1B[44m'},  // Blue
    {'foreground': '\x1B[35m', 'background': '\x1B[45m'},  // Magenta
    {'foreground': '\x1B[36m', 'background': '\x1B[46m'}   // Cyan
  ];

  return colors[index % colors.length];  // Alternate colors based on index
}
