################################################################################
#
#       DedekindCriterion.jl : Dedekinds Criterion for maximality
#
# This file is part of Hecke.
#
# Copyright (c) 2015, 2016: Claus Fieker, Tommy Hofmann
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
#  Copyright (C) 2015, 2016 Tommy Hofmann
#
################################################################################

function dedekind_ispmaximal(O::NfOrd, p::fmpz)
  !isequationorder(O) && error("Order must be an equation order")
  if rem(discriminant(O), p) != 0
    return true, O
  end

  pmaximal = true

  Zy, y = PolynomialRing(ZZ, "y")
  Kx, x = PolynomialRing(ResidueRing(ZZ, p, cached=false), "x", cached=false)

  f = nf(O).pol

  Zyf = Zy(f)

  fmodp = Kx(Zyf)
 
  fac = factor(fmodp)

  g = Zy(1)

  # first build 1/p ( f - prod_{g in fac} g^?)
  for (fi, ei) in fac
    g *= lift(Zy, fi)^ei
  end

  g = Zyf - g

  for i in 0:degree(g)
    q,r = divrem(coeff(g,i),p)
    @assert r == 0
    setcoeff!(g,i,q)
  end

  gmodp = Kx(g)

  U = one(Kx)

  for (fi,ei) in fac
    if ei != 1 && rem(gmodp, fi) == zero(Kx)
      U *= fi
      return false
    end
  end

  return true
end

function dedekind_ispmaximal(O::NfOrd, p::Integer)
  return dedekind_ispmaximal(O, ZZ(p))
end

function dedekind_poverorder(O::NfOrd, p::fmpz)
  _, O = dedekind_test(O, p)
  return O
end

function dedekind_poverorder(O::NfOrd, p::Integer)
  return dedekind_poverorder(O, ZZ(p))
end

function dedekind_test(O::NfOrd, p::fmpz)
  !isequationorder(O) && error("Order must be an equation order")
  
  if rem(discriminant(O), p) != 0
    return true, O
  end

  pmaximal = true
  
  Zy, y = PolynomialRing(ZZ, "y")
  Kx, x = PolynomialRing(ResidueRing(ZZ, p, cached=false), "x", cached=false)

  f = nf(O).pol

  Zyf = Zy(f)

  fmodp = Kx(Zyf)
 
  fac = factor(fmodp)

  g = Zy(1)

  # first build 1/p ( f - prod_{g in fac} g^?)
  for (fi,ei) in fac
    g *= lift(Zy, fi)^ei
  end

  g = Zyf - g

  for i in 0:degree(g)
    q,r = divrem(coeff(g,i),p)
    @assert r == 0
    setcoeff!(g,i,q)
  end

  gmodp = Kx(g)

  U = one(Kx)

  for (fi, ei) in fac
    if ei != 1 && rem(gmodp, fi) == zero(Kx)
      U *= fi
      pmaximal=false
    end
  end

  @assert rem(fmodp, U) == zero(Kx)
  U = divexact(fmodp, U)

  if pmaximal
    return true, O
  end

  @assert rem(discriminant(O),p^2) == 0

  alpha = nf(O)(parent(f)(lift(Zy,U)))

  # build the new basis matrix
  # we have to take the representation matrix of alpha!
  # concatenating the coefficient vector won't help
  n = vcat(num(basis_mat(O))*p,representation_mat(alpha))

  b = FakeFmpqMat(n,p)

  OO = Order(nf(O), sub(hnf(b),degree(O) + 1:2*degree(O), 1:degree(O)))

  OO.isequationorder = false

  OO.disc = divexact(discriminant(O),p^(2*(degree(O)-degree(U))))

  return false, OO
end

function dedekind_test(O::NfOrd, p::Integer)
  return dedekind_test(O, ZZ(p))
end
