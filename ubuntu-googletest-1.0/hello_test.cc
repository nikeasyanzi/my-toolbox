/*
* alarm_test.cpp
*
* Created on: 2019年9月17日
* Author: zhiyulinfeng
*/
#include <stdio.h>
#include <stdlib.h>
#include "gtest/gtest.h"

// Demonstrate some basic assertions.
TEST(HelloTest, BasicAssertions) {
  // Expect two strings not to be equal.
  EXPECT_STRNE("hello", "world");
  // Expect equality.
  EXPECT_EQ(7 * 6, 42);
}
