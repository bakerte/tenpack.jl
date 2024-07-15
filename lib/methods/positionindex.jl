"""
  G = makepos(ninds)

Generates a 1-indexed vector `G` of length `ninds` (0-indexed if `zero=-1`) with first entry 0 and the rest 1.

See also: [`position_incrementer!`](@ref)
"""
function makepos(ninds::intType)
  pos = Array{intType,1}(undef,ninds)
  return makepos!(pos)
end
export makepos

"""
  G = makepos!(pos)

Generates a 1-indexed vector `G` of length `nind` (0-indexed if `zero=-1`) with first entry 0 and the rest 1.

See also: [`position_incrementer!`](@ref)
"""
function makepos!(pos::Array{intType,1})
  if length(pos) > 0
    pos[1] = 0
    @inbounds @simd for g = 2:length(pos)
      pos[g] = 1
    end
  end
  return pos
end
export makepos!

"""
  position_incrementer!(pos,sizes)

Increments a vector (but no entry over `sizes`) by one step.  Will change contents of `pos`.
"""
 function position_incrementer!(pos::Array{G,1},sizes::Union{Array{G,1},Tuple{G,Vararg{G}}}) where G <: intType
  w = 1
  @inbounds pos[w] += 1
  @inbounds while w < length(sizes) && pos[w] > sizes[w]
    pos[w] = 1
    w += 1
    pos[w] += 1
  end
  nothing
end
export position_incrementer!

"""
  ind2pos!(currpos,k,x,index,S)

Converts `x[index]` to a position stored in `currpos` (parallelized) with tensor size `S`

#Arguments:
+`currpos::Array{Array{Z,1},1}`: input position
+`k::Integer`: current thread for `currpos`
+`x::Array{Y,1}`: vector of intput integers to convert
+`index::Integer`: index of input position of `x`
+`S::Array{W,1}`: size of tensor to convert from

See also: [`pos2ind`](@ref) [`pos2ind!`](@ref)
"""
 function ind2pos!(currpos::Array{Array{X,1},1},k::X,x::Array{X,1},index::X,S::Union{NTuple{N,X},Array{X,1}}) where {X <: Integer, N}
  ind2pos!(currpos[k],x[index],S)
  nothing
end

"""
  ind2pos!(currpos,k,x,index,S)

Converts `x` to a position stored in `currpos` (parallelized) with tensor size `S`

#Arguments:
+`currpos::Array{Z,1}`: input position vector
+`x::Y`: input index to convert
+`S::Array{W,1}`: size of tensor to convert from

See also: [`pos2ind`](@ref) [`pos2ind!`](@ref)
"""
function ind2pos!(currpos::Array{X,1},x::X,S::Union{NTuple{N,X},Array{X,1}}) where {X <: Integer, N}
 currpos[1] = x-1
 @inbounds @simd for j = 1:length(S)-1
   val = currpos[j]
   currpos[j+1] = fld(val,S[j])
   currpos[j] = val % S[j] + 1
 end
 @inbounds currpos[size(S,1)] = currpos[size(S,1)] % S[size(S,1)] + 1
 nothing
end

"""
  G = pos2ind(currpos,S)

Generates an index `G` from an input position `currpos` (tuple) with tensor size `S` (tuple)

See also: [`pos2ind!`](@ref)
"""
 function pos2ind(currpos::NTuple{G,P},S::NTuple{G,P}) where {G, P <: Integer}
  x = 0
  @inbounds @simd for i = G:-1:2
    x += currpos[i]-1
    x *= S[i-1]
  end
  @inbounds x += currpos[1]
  return x
end

 function pos2ind(currpos::Array{P,1},S::NTuple{G,P}) where {G, P <: Integer}
  x = 0
  @inbounds @simd for i = G:-1:2
    x += currpos[i]-1
    x *= S[i-1]
  end
  @inbounds x += currpos[1]
  return x
end

function pos2ind(currpos::NTuple{N,P},S::Array{P,1}) where {N, P <: Integer}
  x = 0
  @inbounds @simd for i = N:-1:2
    x += currpos[i]-1
    x *= S[i-1]
  end
  @inbounds x += currpos[1]
  return x
end
export pos2ind

"""
  pos2ind!(currpos,S)

Generates an index in element `j` of input storage array `x` from an input position `currpos` (tuple or vector) with tensor size `S` (tuple)

See also: [`pos2ind`](@ref)
"""
 function pos2ind!(x::Array{X,1},j::Integer,currpos::Union{Array{X,1},NTuple{N,intType}},S::NTuple{N,intType}) where {N, X <: Integer}
  @inbounds val = currpos[end]
  @inbounds @simd for i = N-1:-1:1
    val -= 1
    val *= S[i]
    val += currpos[i]
  end
  @inbounds x[j] = val
  nothing
end
export pos2ind!



function zeropos2ind(currpos::Array{X,1},S::NTuple{P,X},selector::NTuple{G,X}) where X <: Integer where G where P
  x = 0
  @inbounds @simd for i = G:-1:1
    x *= S[selector[i]]
    x += currpos[selector[i]]
  end
  return x+1
end

function ind2zeropos(vec::Array{X,1},S::NTuple{P,X}) where X <: Integer where P
  currpos = Array{X,2}(undef,P,length(vec))
  @inbounds for k = 1:length(vec)
    currpos[1,k] = vec[k]-1
    @inbounds @simd for j = 1:P-1
      val = currpos[j,k]
      currpos[j+1,k] = fld(val,S[j])
      currpos[j,k] = val % S[j]
    end
    currpos[P,k] %= S[end]
  end
  return currpos
end
