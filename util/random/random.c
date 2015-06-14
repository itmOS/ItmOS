#include "util/random/random.h"

static unsigned m_w = 123121;
static unsigned m_z = 992992;

int rand()
{
  m_z = 36969 * (m_z & 0xFF) + (m_z >> 16);
  m_w = 18000 * (m_w & 0xFF) + (m_w >> 16);
  return (m_z << 16) + m_w;
}
