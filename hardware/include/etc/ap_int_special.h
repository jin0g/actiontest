// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.

// 67d7842dbbe25473c3c32b93c0da8047785f30d78e8a024de1b57352245f9689

#ifndef AP_INT_SPECIAL_H
#define AP_INT_SPECIAL_H
#ifndef __SYNTHESIS__
#include <cstdio>
#include <cstdlib>
#endif

#ifndef __AP_COMMON_H__
#error "ap_common.h is required."
#endif

// FIXME AP_AUTOCC cannot handle many standard headers, so declare instead of
// include.
// #include <complex>
namespace ap {
template<typename _Tp> class complex;
}

/*
  TODO: Modernize the code using C++11/C++14
  1. constexpr http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2016/p0415r0.html
  2. move constructor
*/

namespace ap {
/*
   Specialize ap::complex<ap_int> to zero initialization ap_int.

   To reduce the area cost, ap_int is not zero initialized, just like basic
   types float or double. However, libstdc++ provides specialization for float,
   double and long double, initializing image part to 0 when not specified.

   This has become a difficulty in switching legacy code from these C types to
   ap_int. To ease the tranform of legacy code, we have to implement
   specialization of ap::complex<> for our type.

   As ap_int is a template, it is impossible to specialize only the methods
   that causes default initialization of value type in ap::complex<>. An
   explicit full specialization of the template class has to be done, covering
   all the member functions and operators of ap::complex<> as specified
   in standard 26.2.4 and 26.2.5.
*/
template <int _AP_W>
class complex<ap_int<_AP_W> > {
 public:
  typedef ap_int<_AP_W> _Tp;
  typedef _Tp value_type;

  // 26.2.4/1
  // Constructor without argument
  // Default initialize, so that in dataflow, the variable is only written once.
  NODEBUG complex() = default;
  // Constructor with ap_int.
  // Zero initialize image part when not specified, so that `C(1) == C(1,0)`
  NODEBUG complex(const _Tp &__r, const _Tp &__i = _Tp(0))
      : _M_real(__r), _M_imag(__i) {}

  // Constructor with another complex number
  template <typename _Up>
  NODEBUG complex(const complex<_Up> &__z) : _M_real(__z.real()), _M_imag(__z.imag()) {}

#if __cplusplus >= 201103L
  NODEBUG const _Tp& real() const { return _M_real; }
  const _Tp& imag() const { return _M_imag; }
#else
  NODEBUG _Tp& real() { return _M_real; }
  NODEBUG const _Tp& real() const { return _M_real; }
  NODEBUG _Tp& imag() { return _M_imag; }
  NODEBUG const _Tp& imag() const { return _M_imag; }
#endif

  NODEBUG void real(_Tp __val) { _M_real = __val; }

  NODEBUG void imag(_Tp __val) { _M_imag = __val; }

  // Assign this complex number with ap_int.
  // Zero initialize image poarrt, so that `C c; c = 1; c == C(1,0);`
  NODEBUG complex<_Tp> &operator=(const _Tp __t) {
    _M_real = __t;
    _M_imag = _Tp(0);
    return *this;
  }

  // 26.2.5/1
  // Add ap_int to this complex number.
  NODEBUG complex<_Tp> &operator+=(const _Tp &__t) {
    _M_real += __t;
    return *this;
  }

  // 26.2.5/3
  // Subtract ap_int from this complex number.
  NODEBUG complex<_Tp> &operator-=(const _Tp &__t) {
    _M_real -= __t;
    return *this;
  }

  // 26.2.5/5
  // Multiply this complex number by ap_int.
  NODEBUG complex<_Tp> &operator*=(const _Tp &__t) {
    _M_real *= __t;
    _M_imag *= __t;
    return *this;
  }

  // 26.2.5/7
  // Divide this complex number by ap_int.
  NODEBUG complex<_Tp> &operator/=(const _Tp &__t) {
    _M_real /= __t;
    _M_imag /= __t;
    return *this;
  }

  // Assign complex number to this complex number.
  template <typename _Up>
  NODEBUG complex<_Tp> &operator=(const complex<_Up> &__z) {
    _M_real = __z.real();
    _M_imag = __z.imag();
    return *this;
  }

  // 26.2.5/9
  // Add complex number to this.
  template <typename _Up>
  NODEBUG complex<_Tp> &operator+=(const complex<_Up> &__z) {
    _M_real += __z.real();
    _M_imag += __z.imag();
    return *this;
  }

  // 26.2.5/11
  // Subtract complex number from this.
  template <typename _Up>
  NODEBUG complex<_Tp> &operator-=(const complex<_Up> &__z) {
    _M_real -= __z.real();
    _M_imag -= __z.imag();
    return *this;
  }

  // 26.2.5/13
  // Multiply this by complex number.
  template <typename _Up>
  NODEBUG complex<_Tp> &operator*=(const complex<_Up> &__z) {
    const _Tp __r = _M_real * __z.real() - _M_imag * __z.imag();
    _M_imag = _M_real * __z.imag() + _M_imag * __z.real();
    _M_real = __r;
    return *this;
  }

  // 26.2.5/15
  // Divide this by complex number.
  template <typename _Up>
  NODEBUG complex<_Tp> &operator/=(const complex<_Up> &__z) {
    complex<_Tp> cj (__z.real(), -__z.imag());
    complex<_Tp> a = (*this) * cj;
    complex<_Tp> b = cj * __z;
    _M_real = a.real() / b.real();
    _M_imag = a.imag() / b.real();
    return *this;
  }

 private:
  _Tp _M_real;
  _Tp _M_imag;

}; // class complex<ap_int<_AP_W> >


/*
   Non-member operations
   These operations are not required by standard in 26.2.6, but libstdc++
   defines them for
   float, double or long double's specialization.
*/
// Compare complex number with ap_int.
template <int _AP_W>
inline NODEBUG bool operator==(const complex<ap_int<_AP_W> > &__x, const ap_int<_AP_W> &__y) {
  return __x.real() == __y &&
         __x.imag() == 0;
}

// Compare ap_int with complex number.
template <int _AP_W>
inline NODEBUG bool operator==(const ap_int<_AP_W> &__x, const complex<ap_int<_AP_W> > &__y) {
  return __x == __y.real() &&
         0 == __y.imag();
}

// Compare complex number with ap_int.
template <int _AP_W>
inline NODEBUG bool operator!=(const complex<ap_int<_AP_W> > &__x, const ap_int<_AP_W> &__y) {
  return __x.real() != __y ||
         __x.imag() != 0;
}

// Compare ap_int with complex number.
template <int _AP_W>
inline NODEBUG bool operator!=(const ap_int<_AP_W> &__x, const complex<ap_int<_AP_W> > &__y) {
  return __x != __y.real() ||
         0 != __y.imag();
}

}  // namespace ap

#endif  // ifndef AP_INT_SPECIAL_H


