#ifndef SPIN_H_
#define SPIN_H_

#include <stdbool.h>

void setup();

unsigned int spin(int motorPins[4], int limitPin, bool forward,
  unsigned int interval, unsigned int stepCount, bool* limitReached);

unsigned int spinWithRpm(int motorPins[4], int limitPin, float degrees,
  float rpm, bool* limitReached);

unsigned int getIntervalForRpm(float rpm, int revSteps);

unsigned int getStepCountForDegrees(float degrees, int revSteps);

#endif // SPIN_H_
