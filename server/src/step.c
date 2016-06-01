#include <stdio.h>
#include <signal.h>
#include <unistd.h>
#include <sys/time.h>
#include "spin.h"

/*
 * One revolution of the motor is 2540 steps.
 * For 1 RPM, the interval is 23622
 * Max RPM is about 6.
 */

void user1Handler(int signum) {
  signal(SIGUSR1, user1Handler);
}

float timedifference_msec(struct timeval t0, struct timeval t1)
{
    return (t1.tv_sec - t0.tv_sec) * 1000.0f + (t1.tv_usec - t0.tv_usec) / 1000.0f;
}

int main (int argc, char* argv[]) {
  int pins[4];
  int inpin;
  float degrees;
  float rpm;
  if (argc < 6) {
    printf("Usage: step <pin1> <pin2> <pin3> <pin4> <limitpin> <degrees> <rpm>\n");
    _exit(1);
  }

  for (int i = 1; i < 5; i++) {
    sscanf (argv[i],"%d",&pins[i-1]);
  }

  sscanf (argv[5],"%d",&inpin);

  sscanf (argv[6],"%f",&degrees);
  sscanf (argv[7],"%f",&rpm);

  signal(SIGUSR1, user1Handler);

  struct timeval stop, start;
  gettimeofday(&start, NULL);

  setup();
  int stepsCount = spinWithRpm(pins, inpin, degrees, rpm, NULL);

  gettimeofday(&stop, NULL);

  printf("steps: %d time: %f\n", stepsCount, timedifference_msec(start, stop));
  return 0 ;
}
