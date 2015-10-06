function Array(a::fmpz_mat)
  A = Array(BigInt, rows(a), cols(a))
  for i = 1:rows(a)
    for j = 1:cols(a)
      A[i,j] = a[i,j]
    end 
  end
  return A
end

function is_zero_row(M::fmpz_mat, i::Int)
  for j = 1:cols(M)
    if M[i,j] != 0 
      return false
    end
  end
  return true
end

function is_zero_row{T}(M::MatElem{T}, i::Int)
  for j in 1:cols(M)
    if !iszero(M[i,j])
      return false
    end
  end
  return true
end

function is_zero_row{T <: Integer}(M::Array{T, 2}, i::Int)
  for j = 1:Base.size(M, 2)
    if M[i,j] != 0 
      return false
    end
  end
  return true
end

function is_zero_row(M::Array{fmpz, 2}, i::Int)
  for j = 1:Base.size(M, 2)
    if M[i,j] != 0 
      return false
    end
  end
  return true
end

function is_zero_row(M::Array{fmpz, 2}, i::Int)
  for j = 1:Base.size(M, 2)
    if M[i,j] != 0 
      return false
    end
  end
  return true
end

function is_zero_row{T <: RingElem}(M::Array{T, 2}, i::Int)
  for j in 1:Base.size(M, 2)
    if !iszero(M[i,j])
      return false
    end
  end
  return true
end

#computes (hopefully) the hnf for vcat(a*I, m) and returns ONLY the
#non-singular part. By definition, the result wil have full rank
#
#Should be rewritten to use Howell and lifting rather the big HNF
#
function modular_hnf(m::fmpz, a::fmpz_mat, shape::Symbol = :upperright)
  c = vcat(parent(a)(m), a)
  n = cols(a)
  w = window(c, n+1, 1, 2*n, n)
  ccall((:fmpz_mat_scalar_mod_fmpz, :libflint), Void, (Ptr{fmpz_mat}, Ptr{fmpz_mat}, Ptr{fmpz}), &w, &w, &m)
  if shape == :lowerleft
    c = _hnf(c, shape)
    return sub(c, n+1:2*n, 1:n)
  else
    c = hnf(c)
    c = sub(c, 1:n, 1:n)
  end
end

function _lift_howell_to_hnf(x::nmod_mat)
# Assume that x is square, in howell normal form and all non-zero rows are at the bottom
# NOTE: _OUR_ Howell normal form algorithm always puts the rows at the right position
# If row i is non-zero then i is the rightmost non-zero entry
# Thus lifting is just replacing zero diagonal entries
  !issquare(x) && error("Matrix has to be square")
  y = lift_unsigned(x)
  for i in cols(y):-1:1
    z = ccall((:fmpz_mat_entry, :libflint), Ptr{fmpz}, (Ptr{fmpz_mat}, Int, Int), &y, i - 1, i - 1)
    if Bool(ccall((:fmpz_is_zero, :libflint), Int, (Ptr{fmpz}, ), z))
#      z = ccall((:fmpz_mat_entry, :libflint), Ptr{fmpz}, (Ptr{fmpz_mat}, Int, Int), &y, 0, i - 1)
      ccall((:fmpz_set_ui, :libflint), Void, (Ptr{fmpz}, UInt), z, x._n)
#      for k in 1:i-1
#        _swaprows!(y, k, k+1)
#      end
    end
  end
  return y
end

function submat{T <: Integer}(x::nmod_mat, r::UnitRange{T}, c::UnitRange{T})
  z = deepcopy(window(x, r, c))
  return z
end

function submat{T <: Integer}(x::fmpz_mat, r::UnitRange{T}, c::UnitRange{T})
  z = deepcopy(window(x, r, c))
  return z
end

function _hnf_modular(x::fmpz_mat, m::fmpz, shape::Symbol = :lowerleft)
  if abs(m) < fmpz(typemax(UInt))
    y = MatrixSpace(ResidueRing(FlintZZ, m), rows(x), cols(x))(x)
    howell_form!(y, shape)
    y = submat(y, rows(y) - cols(y) + 1:rows(y), 1:cols(y))
    return _lift_howell_to_hnf(y)
  end
  return __hnf_modular(x, m, shape)
end

function __hnf_modular(x::fmpz_mat, m::fmpz, shape::Symbol = :lowerleft)
# See remarks above
  y = deepcopy(x)
  howell_form!(y, m, shape)
  y = submat(y, rows(y) - cols(y) + 1:rows(y), 1:cols(y))
  for i in cols(y):-1:1
    z = ccall((:fmpz_mat_entry, :libflint), Ptr{fmpz}, (Ptr{fmpz_mat}, Int, Int), &y, i - 1, i - 1)
    if Bool(ccall((:fmpz_is_zero, :libflint), Int, (Ptr{fmpz}, ), z))
    #if ccall((:nmod_mat_get_entry, :libflint), Base.GMP.Limb, (Ptr{nmod_mat}, Int, Int), &x, i - 1, i - 1) == 0
#      z = ccall((:fmpz_mat_entry, :libflint), Ptr{fmpz}, (Ptr{fmpz_mat}, Int, Int), &y, 0, i - 1)
      ccall((:fmpz_set, :libflint), Void, (Ptr{fmpz}, Ptr{fmpz}), z, &m)
#      for k in 1:i-1
#        _swaprows!(y, k, k+1)
#      end
    end
  end
  return y
end

function _hnf(x::fmpz_mat, shape::Symbol = :upperright)
  if shape == :lowerleft
    h = hnf(_swapcols(x))
    _swapcols!(h)
    _swaprows!(h)
    return h::fmpz_mat
  end
  return hnf(x)::fmpz_mat
end


function howell_form!(x::fmpz_mat, m::fmpz, shape::Symbol = :upperright)
  if shape == :lowerleft
    _swapcols!(x)
    ccall((:_fmpz_mat_howell, :libflint), Int, (Ptr{fmpz_mat}, Ptr{fmpz}), &x, &m)
    _swapcols!(x)
    _swaprows!(x)
  else
    ccall((:_fmpz_mat_howell, :libflint), Int, (Ptr{fmpz_mat}, Ptr{fmpz}), &x, &m)
  end
end

function howell_form(x::fmpz_mat, m::fmpz, shape::Symbol = :upperright)
  y = deepcopy(x)
  howell_form!(y, m, shape)
  return y
end

function howell_form!(x::nmod_mat, shape::Symbol = :upperright)
  if shape == :lowerleft
    _swapcols!(x)
    ccall((:_nmod_mat_howell, :libflint), Int, (Ptr{nmod_mat}, ), &x)
    _swapcols!(x)
    _swaprows!(x)
  else
    ccall((:_nmod_mat_howell, :libflint), Int, (Ptr{nmod_mat}, ), &x)
  end
end

function howell_form(x::nmod_mat, shape::Symbol = :upperright)
  y = deepcopy(x)
  howell_form!(y, shape)
  return y
end

function _swaprows(x::fmpz_mat)
  y = deepcopy(x)
  _swaprows!(y)
  return y
end

function _swapcols(x::fmpz_mat)
  y = deepcopy(x)
  _swapcols!(y)
  return y
end

function _swaprows!(x::fmpz_mat)
  r = rows(x)
  c = cols(x)

  if r == 1
    return x
  end

  if r % 2 == 0
    for i in 1:div(r,2)
      for j = 1:c
        # we swap x[i,j] <-> x[r-i+1,j]
        s = ccall((:fmpz_mat_entry, :libflint), Ptr{fmpz}, (Ptr{fmpz_mat}, Int, Int), &x, i - 1, j - 1)
        t = ccall((:fmpz_mat_entry, :libflint), Ptr{fmpz}, (Ptr{fmpz_mat}, Int, Int), &x, (r - i + 1) - 1, j - 1)
        ccall((:fmpz_swap, :libflint), Void, (Ptr{fmpz}, Ptr{fmpz}), t, s)
      end
    end
  else
    for i in 1:div(r-1,2)
      for j = 1:c
        # we swap x[i,j] <-> x[r-i+1,j]
        s = ccall((:fmpz_mat_entry, :libflint), Ptr{fmpz}, (Ptr{fmpz_mat}, Int, Int), &x, i - 1, j - 1)
        t = ccall((:fmpz_mat_entry, :libflint), Ptr{fmpz}, (Ptr{fmpz_mat}, Int, Int), &x, (r - i + 1) - 1, j - 1)
        ccall((:fmpz_swap, :libflint), Void, (Ptr{fmpz}, Ptr{fmpz}), t, s)
      end
    end
  end
  nothing
end

function _swaprows!(x::fmpz_mat, i::Int, j::Int)
  ccall((:_fmpz_mat_swap_rows, :libflint), Void, (Ptr{fmpz_mat}, Int, Int), &x, i-1, j-1)
  nothing
end

function _swaprows!(x::nmod_mat, i::Int, j::Int)
  ccall((:_nmod_mat_swap_rows, :libflint), Void, (Ptr{nmod_mat}, Int, Int), &x, i-1, j-1)
#  for k in 1:rows(x)
#    s = ccall((:nmod_mat_get_entry, :libflint), Base.GMP.Lim, (Ptr{nmod_mat}, Int, Int), &x, i, k)
#    t = ccall((:nmod_mat_get_entry, :libflint), Base.GMP.Lim, (Ptr{nmod_mat}, Int, Int), &x, j, k)
#    set_entry!(x, i, k, t)
#    set_entry!(y, j, k, s)
#  end
  nothing
end
  

function _swaprows!(x::nmod_mat)
  r = rows(x)
  c = cols(x)

  if r == 1
    return nothing
  end

  if r % 2 == 0
    for i in 1:div(r,2)
      for j = 1:c
        # we swap x[i,j] <-> x[r-i+1,j]
        s = ccall((:nmod_mat_get_entry, :libflint), Base.GMP.Limb, (Ptr{nmod_mat}, Int, Int), &x, i - 1, j - 1)
        t = ccall((:nmod_mat_get_entry, :libflint), Base.GMP.Limb, (Ptr{nmod_mat}, Int, Int), &x, (r - i + 1) - 1, j - 1)
        set_entry!(x, r - i + 1, j, s)
        set_entry!(x, i, j, t)
      end
    end
  else
    for i in 1:div(r-1,2)
      for j = 1:c
        # we swap x[i,j] <-> x[r-i+1,j]
        s = ccall((:nmod_mat_get_entry, :libflint), Base.GMP.Limb, (Ptr{nmod_mat}, Int, Int), &x, i - 1, j - 1)
        t = ccall((:nmod_mat_get_entry, :libflint), Base.GMP.Limb, (Ptr{nmod_mat}, Int, Int), &x, (r - i + 1) - 1, j - 1)
        set_entry!(x, i, j, t)
        set_entry!(x, r - i + 1, j, s)
      end
    end
  end
  nothing
end

function _swapcols!(x::nmod_mat)
  r = rows(x)
  c = cols(x)

  if c == 1
    return nothing
  end

  if c % 2 == 0
    for i in 1:div(c,2)
      for j = 1:r
        # swap x[j,i] <-> x[j,c-i+1]
        s = ccall((:nmod_mat_get_entry, :libflint), Base.GMP.Limb, (Ptr{nmod_mat}, Int, Int), &x, j - 1, i - 1)
        t = ccall((:nmod_mat_get_entry, :libflint), Base.GMP.Limb, (Ptr{nmod_mat}, Int, Int), &x, j - 1, (c - i + 1 ) - 1)
        set_entry!(x, j, i, t)
        set_entry!(x, j, c - i + 1, s)
      end
    end
  else
    for i in 1:div(c-1,2)
      for j = 1:r
        # swap x[j,i] <-> x[j,c-i+1]
        s = ccall((:nmod_mat_get_entry, :libflint), Base.GMP.Limb, (Ptr{nmod_mat}, Int, Int), &x, j - 1, i - 1)
        t = ccall((:nmod_mat_get_entry, :libflint), Base.GMP.Limb, (Ptr{nmod_mat}, Int, Int), &x, j - 1, (c - i + 1 ) - 1)
        set_entry!(x, j, i, t)
        set_entry!(x, j, c - i + 1, s)
      end
    end
  end
  nothing
end

function _swapcols!(x::fmpz_mat)
  r = rows(x)
  c = cols(x)

  if c == 1
    return x
  end

  if c % 2 == 0
    for i in 1:div(c,2)
      for j = 1:r
        # swap x[j,i] <-> x[j,c-i+1]
        s = ccall((:fmpz_mat_entry, :libflint), Ptr{fmpz}, (Ptr{fmpz_mat}, Int, Int), &x, j - 1, i - 1)
        t = ccall((:fmpz_mat_entry, :libflint), Ptr{fmpz}, (Ptr{fmpz_mat}, Int, Int), &x, j - 1, (c - i + 1 ) - 1)
        ccall((:fmpz_swap, :libflint), Void, (Ptr{fmpz}, Ptr{fmpz}), t, s)
      end
    end
  else
    for i in 1:div(c-1,2)
      for j = 1:r
        # swap x[j,i] <-> x[j,c-i+1]
        s = ccall((:fmpz_mat_entry, :libflint), Ptr{fmpz}, (Ptr{fmpz_mat}, Int, Int), &x, j - 1, i - 1)
        t = ccall((:fmpz_mat_entry, :libflint), Ptr{fmpz}, (Ptr{fmpz_mat}, Int, Int), &x, j - 1, (c - i + 1 ) - 1)
        ccall((:fmpz_swap, :libflint), Void, (Ptr{fmpz}, Ptr{fmpz}), t, s)
      end
    end
  end
  nothing
end

################################################################################
# 
################################################################################

function max(a::fmpz_mat)
  m = ccall((:fmpz_mat_entry, :libflint), Ptr{fmpz}, (Ptr{fmpz_mat}, Int, Int), &a, 0,0)
  for i=1:rows(a)
    for j=1:cols(a)
      z = ccall((:fmpz_mat_entry, :libflint), Ptr{fmpz}, (Ptr{fmpz_mat}, Int, Int), &a, i-1, j-1)
      if ccall((:fmpz_cmpabs, :libflint), Cint, (Ptr{fmpz}, Ptr{fmpz}), m, z) < 0
        m = z
      end
    end
  end
  r = fmpz()
  ccall((:fmpz_abs, :libflint), Void, (Ptr{fmpz}, Ptr{fmpz}), &r, m)
  return r
end

function lift_unsigned(a::nmod_mat)
  z = MatrixSpace(FlintZZ, rows(a), cols(a))()
  ccall((:fmpz_mat_set_nmod_mat_unsigned, :libflint), Void,
          (Ptr{fmpz_mat}, Ptr{nmod_mat}), &z, &a)
  return z
end

################################################################################
# possibly a slice or window in fmpz_mat?
# the nr x nc matrix starting in (a,b)
################################################################################

function submat(A::fmpz_mat, a::Int, b::Int, nr::Int, nc::Int)
  @assert nr >= 0 && nc >= 0
  M = MatrixSpace(FlintZZ, nr, nc)()::fmpz_mat
  t = ZZ()
  for i = 1:nr
    for j = 1:nc
      getindex!(t, A, a+i-1, b+j-1)
      M[i,j] = t
    end
  end
  return M
end

function submat{T <: Integer}(A::fmpz_mat, r::UnitRange{T}, c::UnitRange)
  @assert !isdefined(r, :step) || r.step==1
  @assert !isdefined(c, :step) || c.step==1
  return submat(A, r.start, c.start, r.stop-r.start+1, c.stop-c.start+1)::fmpz_mat
end


function sub(A::fmpz_mat, r::UnitRange, c::UnitRange)
  @assert !isdefined(r, :step) || r.step==1
  @assert !isdefined(c, :step) || c.step==1
  return submat(A, r.start, c.start, r.stop-r.start+1, c.stop-c.start+1)::fmpz_mat
end
