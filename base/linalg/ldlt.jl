immutable LDLt{T,S<:AbstractMatrix{T}} <: Factorization{T}
    matrix::S
end

size(S::LDLt) = size(S.matrix)
size(S::LDLt, i::Integer) = size(S.matrix, i)

convert{T,S,U}(::Type{LDLt{T}}, F::LDLt{S,U}) = convert(LDLt{T,U}, F)
convert{T,S}(::Type{LDLt{T,S}}, F::LDLt) = LDLt{T,S}(convert(S, F.matrix))
convert{T,S,U}(::Type{Factorization{T}}, F::LDLt{S,U}) = convert(LDLt{T,U}, F)

# SymTridiagonal
function ldltfact!{T<:Real}(S::SymTridiagonal{T})
	n = size(S,1)
	d = S.dv
	e = S.ev
	@inbounds for i = 1:n-1
		e[i] /= d[i]
		d[i+1] -= abs2(e[i])*d[i]
		d[i+1] > 0 || throw(PosDefException(i+1))
	end
	return LDLt{T,SymTridiagonal{T}}(S)
end
function ldltfact{T}(M::SymTridiagonal{T})
	S = typeof(one(T)/one(T))
	return S == T ? ldltfact!(copy(M)) : ldltfact!(convert(SymTridiagonal{S}, M))
end
function A_ldiv_B!{T}(S::LDLt{T,SymTridiagonal{T}}, B::AbstractVecOrMat{T})
	n, nrhs = size(B, 1), size(B, 2)
	size(S,1) == n || throw(DimensionMismatch(""))
	d = S.matrix.dv
	l = S.matrix.ev
	@inbounds begin
		for i = 2:n
			li1 = l[i-1]
			for j = 1:nrhs
				B[i,j] -= li1*B[i-1,j]
			end
		end
		dn = d[n]
		for j = 1:nrhs
			B[n,j] /= dn
		end
		for i = n-1:-1:1
			di = d[i]
			li = l[i]
			for j = 1:nrhs
				B[i,j] /= di
				B[i,j] -= li*B[i+1,j]
			end
		end
	end
	return B
end