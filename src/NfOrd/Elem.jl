################################################################################
#
#  NfOrd_elt.jl : Elements in orders of number fields
#
################################################################################

import Base: in

export NfOrdElem

export elem_in_order, rand, rand!

################################################################################
#
#  Types and memory management
#
################################################################################

#type NfOrdElem
#  elem_in_nf::nf_elem
#  elem_in_basis::Array{fmpz, 1}
#  has_coord::Bool
#  parent::NfOrd
#
#  function NfOrdElem(O::NfOrd, a::nf_elem)
#    z = new()
#    z.elem_in_nf = deepcopy(a)
#    z.elem_in_basis = Array(fmpz, degree(O))
#    z.parent = O
#    z.has_coord = false
#    return z
#  end
#
##  function NfOrdElem(O::NfOrd, a::nf_elem, check::Bool)
##    z = new()
##    if check
##      (x,y) = _check_elem_in_order(a,O)
##      !x && error("Number field element not in the order")
##      z.has_coord = true
##      z.elem_in_basis = y
##    end
##    z.elem_in_nf = deepcopy(a)
##    z.parent = O
##    return z
##  end
##
#  function NfOrdElem(O::NfOrd, a::nf_elem, arr::Array{fmpz, 1})
#    z = new()
#    z.parent = O
#    z.elem_in_nf = deepcopy(a)
#    z.has_coord = true
#    z.elem_in_basis = deepcopy(arr)
#    return z
#  end
#
#  function NfOrdElem(O::NfOrd, arr::Array{fmpz, 1})
#    z = new()
#    z.elem_in_nf = Base.dot(basis_nf(O), arr)
#    z.has_coord = true
#    z.elem_in_basis = deepcopy(arr)
#    z.parent = O
#    return z
#  end
#
#  function NfOrdElem{T <: Integer}(O::NfOrd, arr::Array{T, 1})
#    return NfOrdElem(O, map(ZZ, arr))
#  end
#
#  function NfOrdElem(O::NfOrd)
#    z = new()
#    z.parent = O
#    z.elem_in_nf = parent(O).nf()
#    z.elem_in_basis = Array(fmpz, degree(O))
#    z.has_coord = false
#    return z
#  end
#end

#function NfOrdElem!(O::NfOrd, a::nf_elem)
#  z = O()
#  z.elem_in_nf = a
#end

parent(a::NfOrdElem) = a.parent

################################################################################
#
#  Field access
#
################################################################################

function elem_in_nf(a::NfOrdElem)
  if isdefined(a, :elem_in_nf)
    return a.elem_in_nf
  end
#  if isdefined(a, :elem_in_basis)
#    a.elem_in_nf = dot(_basis(O), a.elem_in_basis)
#    return a.elem_in_nf
#  end
  error("Not a valid order element")
end

function elem_in_basis(a::NfOrdElem)
  @vprint :NfOrd 2 "Computing the coordinates of $a\n"
#  if isdefined(a, :elem_in_basis)
#    @vprint :NfOrd 2 "allready definied\n"
#    return a.elem_in_basis
#  end
#  if isdefined(a, :elem_in_nf)
  if a.has_coord
    return a.elem_in_basis
  else
    (x,y) = _check_elem_in_order(a.elem_in_nf,parent(a))
    !x && error("Number field element not in the order")
    a.elem_in_basis = y
    a.has_coord = true
    return a.elem_in_basis
#  end
    error("Not a valid order element")
  end
end

################################################################################
#
#  Special elements
#
################################################################################

function zero(O::NfOrdCls)
  z = O()
  z.elem_in_nf = zero(O.nf)
  return z
end

################################################################################
#
#  String I/O
#
################################################################################

function show(io::IO, a::NfOrdElem)
  print(io, a.elem_in_nf)
end

################################################################################
#
#  Parent object overloading
#
################################################################################
 
#function call(O::NfOrd, a::nf_elem, check::Bool = true)
#  if check
#    (x,y) = _check_elem_in_order(a,O)
#    !x && error("Number field element not in the order")
#    return NfOrdElem(O, a, y)
#  else
#    return NfOrdElem(O, a)
#  end
#end
#
#function call(O::NfOrd, a::nf_elem, arr::Array{fmpz, 1})
#  return NfOrdElem(O, a, arr)
#end
#
#function call(O::NfOrd, arr::Array{fmpz, 1})
#  return NfOrdElem(O, arr)
#end
#
#function call{T <: Integer}(O::NfOrd, arr::Array{T, 1})
#  return NfOrdElem(O, arr)
#end
#
#function call(O::NfOrd)
#  return NfOrdElem(O)
#end

################################################################################
#
#  Binary operations
#
################################################################################

function *(x::NfOrdElem, y::NfOrdElem)
  z = parent(x)()
  z.elem_in_nf = elem_in_nf(x)*elem_in_nf(y)
  return z
end

function *(x::NfOrdElem, y::fmpz)
  z = parent(x)()
  z.elem_in_nf = x.elem_in_nf * y
  return z
end

*(x::fmpz, y::NfOrdElem) = y * x

*(x::Integer, y::NfOrdElem) = fmpz(x)* y

*(x::NfOrdElem, y::Integer) = y * x

function +(x::NfOrdElem, y::NfOrdElem)
  z = parent(x)()
  z.elem_in_nf = x.elem_in_nf + y.elem_in_nf
  return z
end

function -(x::NfOrdElem, y::NfOrdElem)
  z = parent(x)()
  z.elem_in_nf = x.elem_in_nf - y.elem_in_nf
  return z
end


function +(x::NfOrdElem, y::fmpz)
  z = parent(x)()
  z.elem_in_nf = x.elem_in_nf + y
  return z
end

+(x::fmpz, y::NfOrdElem) = y + x

function ^(x::NfOrdElem, y::Int)
  z = parent(x)()
  z.elem_in_nf = x.elem_in_nf^y
  return z
end

################################################################################
#
#  Modular reduction
#
################################################################################

function mod(a::NfOrdElem, m::fmpz)
  ar = copy(elem_in_basis(a))
  for i in 1:degree(parent(a))
    ar[i] = mod(ar[i],m)
  end
  return parent(a)(ar)
end

==(x::NfOrdElem, y::NfOrdElem) = x.elem_in_nf == y.elem_in_nf
 
################################################################################
#
#  Modular exponentiation
#
################################################################################

function powermod(a::NfOrdElem, i::fmpz, p::fmpz)
  if i == 0 then
    z = parent(a)()
    z.elem_in_nf = one(nf(parent(a)))
    return z
  end
  if i == 1 then
    b = mod(a,p)
    return b
  end
  if mod(i,2) == 0 
    j = div(i,2)
    b = powermod(a, j, p)
    b = b^2
    b = mod(b,p)
    return b
  end
  b = mod(a*powermod(a,i-1,p),p)
  return b
end  

powermod(a::NfOrdElem, i::Integer, p::Integer)  = powermod(a, ZZ(i), ZZ(p))

powermod(a::NfOrdElem, i::fmpz, p::Integer)  = powermod(a, i, ZZ(p))

powermod(a::NfOrdElem, i::Integer, p::fmpz)  = powermod(a, ZZ(i), p)

################################################################################
#
#  Number field element conversion/containment
#
################################################################################

function in(a::nf_elem, O::NfOrd)
  x, = _check_elem_in_order(a::nf_elem, O::NfOrd)
  return x
end

function elem_in_order(a::nf_elem, O::NfOrd)
  (x,y) = _check_elem_in_order(a, O)
  return (x, O(y))
end

################################################################################
#
#  Representation matrices
#
################################################################################

function representation_mat(a::NfOrdElem)
  O = parent(a)
  A = representation_mat(a, parent(a).nf)
  A = basis_mat(O)*A*basis_mat_inv(O)
  !(A.den == 1) && error("Element not in order")
  return A.num
end

function representation_mat(a::NfOrdElem, K::AnticNumberField)
  @assert parent(a.elem_in_nf) == K
  d = denominator(a.elem_in_nf)
  b = d*a.elem_in_nf
  A = representation_mat(b)
  z = FakeFmpqMat(A,d)
  return z
end

################################################################################
#
#  Trace
#
################################################################################

function trace(a::NfOrdElem)
  return FlintZZ(trace(elem_in_nf(a)))
end

################################################################################
#
#  Norm
#
################################################################################

function norm(a::NfOrdElem)
  return FlintZZ(norm(elem_in_nf(a)))
end

################################################################################
#
#  Random element generation
#
################################################################################

function rand!{T <: Integer}(z::NfOrdElem, O::NfOrdCls, R::UnitRange{T})
  y = O()
  ar = rand(R, degree(O))
  B = basis(O)
  mul!(z, ar[1], B[1])
  for i in 2:degree(O)
    mul!(y, ar[i], B[i])
    add!(z, z, y)
  end
  return z
end

function rand{T <: Integer}(O::NfOrdCls, R::UnitRange{T})
  z = O()
  rand!(z, O, R)
  return z
end

function rand!(z::NfOrdElem, O::NfOrdCls, n::Integer)
  return rand!(z, O, -n:n)
end

function rand(O::NfOrdCls, n::Integer)
  return rand(O, -n:n)
end

function rand!(z::NfOrdElem, O::NfOrdCls, n::fmpz)
  return rand!(z, O, BigInt(n))
end

function rand(O::NfOrdCls, n::fmpz)
  return rand(O, BigInt(n))
end
  
################################################################################
#
#  Unsafe operations
#
################################################################################

function add!(z::NfOrdElem, x::NfOrdElem, y::NfOrdElem)
  z.elem_in_nf = x.elem_in_nf + y.elem_in_nf
  if x.has_coord && y.has_coord
    for i in 1:degree(parent(x))
      z.elem_in_basis[i] = x.elem_in_basis[i] + y.elem_in_basis[i]
    end
    z.has_coord = true
  else
    z.has_coord = false
  end
  nothing
end

function mul!(z::NfOrdElem, x::NfOrdElem, y::NfOrdElem)
  z.elem_in_nf = x.elem_in_nf * y.elem_in_nf
  z.has_coord = false
  nothing
end

function mul!(z::NfOrdElem, x::Integer, y::NfOrdElem)
  mul!(z, ZZ(x), y)
  nothing
end

mul!(z::NfOrdElem, x::NfOrdElem, y::Integer) = mul!(z, y, x)

function mul!(z::NfOrdElem, x::fmpz, y::NfOrdElem)
  z.elem_in_nf = x * y.elem_in_nf
  if y.has_coord
    for i in 1:degree(parent(z))
      z.elem_in_basis[i] = x*y.elem_in_basis[i]
    end
  end
  z.has_coord = true
  nothing
end

function add!(z::NfOrdElem, x::fmpz, y::NfOrdElem)
  z.elem_in_nf = y.elem_in_nf + x
  nothing
end

add!(z::NfOrdElem, x::NfOrdElem, y::fmpz) = add!(z, y, x)

function add!(z::NfOrdElem, x::Integer, y::NfOrdElem)
  z.elem_in_nf = x + y.elem_in_nf
  nothing
end

add!(z::NfOrdElem, x::NfOrdElem, y::Integer) = add!(z, y, x)

mul!(z::NfOrdElem, x::NfOrdElem, y::fmpz) = mul!(z, y, x)

dot(x::fmpz, y::nf_elem) = x*y

dot(x::nf_elem, y::fmpz) = x*y

dot(x::NfOrdElem, y::Int64) = y*x

Base.call(K::AnticNumberField, x::NfOrdElem) = elem_in_nf(x)

Base.promote_rule{T <: Integer}(::Type{NfOrdElem}, ::Type{T}) = NfOrdElem
