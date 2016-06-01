#include <stdio.h>
#include <signal.h>
#include <unistd.h>
#include <sys/time.h>
#include "spin.h"

#ifdef DEBUG
#define DEBUG_PRINT(...) do{ printf( __VA_ARGS__ ); } while( false )
#else
#define DEBUG_PRINT(...) do{ } while ( false )
#endif

struct timeval tickTime = { 0 };

void tick(int signum) {
  DEBUG_PRINT("tick!\n");
  gettimeofday(&tickTime, NULL);
  signal(SIGUSR1, tick);
}

int timedifference_microsec(struct timeval t0, struct timeval t1)
{
    return (t1.tv_sec - t0.tv_sec) * 1000000 + (t1.tv_usec - t0.tv_usec);
}

int main (int argc, char* argv[]) {
  int pins[4];
  int inpin;
  float rpm;

  setbuf(stdout, NULL);

  signal(SIGUSR1, tick);

  if (argc < 6) {
    printf("Usage: smoothticker <pin1> <pin2> <pin3> <pin4> <limitpin> <rpm>\n");
    _exit(1);
  }

  for (int i = 1; i < 5; i++) {
    sscanf (argv[i],"%d",&pins[i-1]);
  }
  sscanf (argv[5],"%d",&inpin);
  sscanf (argv[6],"%f",&rpm);

  setup();

  int revolutionTime = (unsigned int)(60000000 / rpm) * GEAR_RATIO;

  unsigned int interval = getIntervalForRpm(rpm, REVOLUTION);
  unsigned int stepsForRevolution = getStepCountForDegrees(360.0f * GEAR_RATIO, REVOLUTION);

  struct timeval endTime;
  spinWithRpm(pins, inpin, 0, rpm, NULL);
  gettimeofday(&endTime, NULL);

  while (1) {
    if (tickTime.tv_sec == 0) {
      DEBUG_PRINT("waiting for tick..\n");
      pause();
    }

    int deltaTime = timedifference_microsec(tickTime, endTime);
    tickTime.tv_sec = 0;

#ifdef DEBUG
    DEBUG_PRINT("delta: %f steps it took: %d\n", (float)deltaTime/1000000, stepsForRevolution);
#endif

    if (deltaTime > revolutionTime) {
      interval = getIntervalForRpm(rpm, REVOLUTION);
    } else {
      // Consider not correcting for fast cycles (deltaTime < 0)
      interval = (revolutionTime - deltaTime) / stepsForRevolution;
      DEBUG_PRINT("new interval: %d\n", interval);
    }

    stepsForRevolution = spin(pins, inpin, true, interval, 0, NULL);
    gettimeofday(&endTime, NULL);
  }
  return 0 ;
}
