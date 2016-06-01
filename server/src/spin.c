#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "spin.h"

#ifdef EMULATE
#include <unistd.h>
unsigned int _counter;
#define OUTPUT 1
#define INPUT 1
#define TRUE 1
#define pinMode(x, y) do{ } while ( false )
#define digitalWrite(x, y) do{ } while ( false )
#define delayMicroseconds(x) do { usleep(x); } while ( false )
#define wiringPiSetup() do{ _counter = 0; } while ( false )
int digitalRead(int pin) {
  unsigned int stepCount = getStepCountForDegrees(720, REVOLUTION);
  if (++_counter > stepCount)
    _counter = 0;
  return _counter < stepCount/2 ? 1 : 0;
}
#else
#include <wiringPi.h>
#endif

const int STEPS[][4] = {
  {1, 0, 0, 1},
  {0, 0, 1, 1},
  {0, 1, 1, 0},
  {1, 1, 0, 0}
};

void setup() {
  wiringPiSetup();
}

unsigned int spin(int motorPins[4], int limitPin, bool forward,
  unsigned int interval, unsigned int stepCount, bool* limitReached) {
  // printf("spin %d %d %d\n", forward, interval, stepCount);

  for (int i = 0; i < 4; i++) {
    pinMode(motorPins[i], OUTPUT);
  }

  if (limitPin >= 0)
    pinMode (limitPin, INPUT);

  int lastRead;
  if (limitPin >= 0) {
    lastRead = digitalRead(limitPin);
  }

  int step = 0;
  unsigned int steps = 0;

  while (TRUE) {
    step = step >= 3 ? 0 : step + 1;

    for (int i = 0; i < 4; i++) {
      digitalWrite (motorPins[i], STEPS[step][forward ? i : 3 - i]);
    }

    steps++;

    if (stepCount && steps >= stepCount) {
      if (limitReached != NULL) *limitReached = false;
      break;
    }

    if (limitPin >= 0) {
      int newRead = digitalRead(limitPin);
      if (!lastRead && newRead) {
        if (limitReached != NULL) *limitReached = true;
        break;
      }

      lastRead = newRead;
    }

    delayMicroseconds(interval);
  }

  return steps;

}

unsigned int getIntervalForRpm(float rpm, int revSteps) {
  float rpmInterval = 1000000.0/(revSteps/60.0);
  return (int)roundf((1 / rpm * rpmInterval));
}

unsigned int getStepCountForDegrees(float degrees, int revSteps) {
  float stepCount = degrees / 360 * revSteps;

  return abs((int)(roundf(stepCount)));
}

unsigned int spinWithRpm(int motorPins[4], int limitPin, float degrees,
  float rpm, bool* limitReached) {
  int stepCount = getStepCountForDegrees(degrees, REVOLUTION);
  int interval = getIntervalForRpm(rpm, REVOLUTION);
  bool forward = degrees >= 0;
  return spin(motorPins, limitPin, forward, interval, stepCount, limitReached);
}
