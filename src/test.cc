#include <cctk.h>
#include <cctk_Arguments.h>

#include <nsimd/nsimd-all.hpp>

#include <string>
#include <vector>

// copied from NSIMD tutorial.cpp
namespace {

template <typename T>
void uppercase_scalar(T *dst, const T *src, int n) {
  for (int i = 0; i < n; i++) {
    if (src[i] >= 'a' && src[i] <= 'z') {
      dst[i] = src[i] + ('A' - 'a');
    } else {
      dst[i] = src[i];
    }
  }
}

template <typename T>
void uppercase_simd(T *dst, const T *src, int n) {
  using namespace nsimd;
  typedef pack<T> p_t;
  typedef packl<T> pl_t;
  int l = len<p_t>();

  int i;
  for (i = 0; i + l <= n; i += l) {
    p_t text = loadu<p_t>(src + i);
    pl_t mask = text >= 'a' && text <= 'z';
    p_t then_pack = text + ('A' - 'a');
    p_t TEXT = if_else(mask, then_pack, text);
    storeu(dst + i, TEXT);
  }

  pl_t mask = mask_for_loop_tail<pl_t>(i, n);
  p_t text = maskz_loadu(mask, src + i);
  p_t TEXT = if_else(text >= 'a' && text <= 'z', text + ('A' - 'a'), text);
  mask_storeu(mask, dst + i, TEXT);
}

extern "C"
void NSIMD_Test(CCTK_ARGUMENTS)
{
  const std::string input = "Cactus Computational Toolkit";

  CCTK_VINFO("Orignal text         : %s", input.c_str());

  std::vector<i8> dst_scalar(input.size() + 1);
  uppercase_scalar(&dst_scalar[0], (i8 *)input.c_str(), (int)input.size());
  CCTK_VINFO("Scalar uppercase text: %s", dst_scalar.data());

  std::vector<i8> dst_simd(input.size() + 1);
  uppercase_simd(&dst_simd[0], (i8 *)input.c_str(), (int)input.size());
  CCTK_VINFO("NSIMD uppercase text : %s",  dst_simd.data());

  if(dst_simd != dst_scalar) {
    CCTK_VERROR("NSIMD failed its self test: %s (scalar) != %s (SIMD)",
                dst_scalar.data(), dst_simd.data());
  }
}
}
