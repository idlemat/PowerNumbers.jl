module PowerNumbers

using Base, DualNumbers, LinearAlgebra

import Base: convert, *, +, -, ==, <, <=, >, !, !=, >=, /, ^, \, in, isapprox
import Base: exp, atanh, log1p, abs, log, inv, real, imag, conj, sqrt, 
                sin, cos, cbrt, abs2, log10, log2, exp, exp2, expm1, 
                sin, cos, tan, sec, csc, cot, sind, cosd, tand, secd, cscd, cotd, asin, acos, 
                atan, asec, acsc, acot, asind, acosd, atand, asecd, acscd, acotd, sinh, cosh, 
                tanh, sech, csch, coth, asinh, acosh, asech, acsch, acoth, deg2rad, rad2deg 
import DualNumbers: Dual, realpart, epsilon, dual

export PowerNumber, LogNumber

include("LogNumber.jl")

struct PowerNumber{T<:Number,V<:Number} <: Number
    A::T
    B::T
    α::V
    β::V
    PowerNumber{T,V}(A,B,α,β) where {T<:Number,V<:Number} = 
    if α > β 
        error("Must have α<=β") 
    elseif α == β 
        new{T,V}(0,A+B,β,β)
    elseif A == 0
        new{T,V}(0,B,β,β)
    else
        new{T,V}(A,B,α,β)
    end
end

PowerNumber(a::T, b::T, c::V, d::V) where {T,V} = PowerNumber{T,V}(a,b,c,d)
PowerNumber(a,b,c,d) = PowerNumber(promote(a,b)..., promote(c,d)...)
PowerNumber(a,b) = PowerNumber(0,a,b,b)

apart(z::PowerNumber) = z.A
bpart(z::PowerNumber) = z.B
alpha(z::PowerNumber) = z.α
beta(z::PowerNumber) = z.β

PowerNumber(x::Dual) = PowerNumber(realpart(x), epsilon(x), 0, 1)
Dual(x::PowerNumber) = alpha(x) == 0 && beta(x) == 1 ? Dual(apart(x), bpart(x)) : throw("α, β must equal 0, 1 to convert to dual.")
dual(x::PowerNumber) = Dual(x)

function (x::PowerNumber)(ε) 
    a,b,α,β = apart(x),bpart(x),alpha(x),beta(x)
    a*ε^α + b*ε^β
end

function +(x::PowerNumber, y::PowerNumber)
    a,b,α,β = apart(x),bpart(x),alpha(x),beta(x)
    c,d,γ,δ = apart(y),bpart(y),alpha(y),beta(y)
    exps = [α,β,γ,δ]
    coef = [a,b,c,d]
    list = sort(unique(exps))
    if length(list) == 1
        return PowerNumber(sum(coef),list[1]) 
    end
    for i in 2:length(list)-1
        tot1 = sum(coef .* (exps .≈ list[i-1]))
        tot2 = sum(coef .* (exps .≈ list[i]))
        if tot2 != 0 
            return PowerNumber(tot1,tot2,list[i-1],list[i])
        end
    end
    tot1 = sum(coef .* (exps .≈ list[end-1]))
    tot2 = sum(coef .* (exps .≈ list[end]))
    return PowerNumber(tot1,tot2,list[end-1],list[end])
end

+(x::PowerNumber, y::Number) = x + PowerNumber(0,y,0,0)
+(y::Number, x::PowerNumber) = +(x::PowerNumber, y::Number)

function *(x::PowerNumber, y::PowerNumber)
    a,b,α,β = apart(x),bpart(x),alpha(x),beta(x)
    c,d,γ,δ = apart(y),bpart(y),alpha(y),beta(y)
    return PowerNumber(a*c,α+γ) + PowerNumber(b*c,β+γ) + PowerNumber(a*d,α+δ) + PowerNumber(b*d,β+δ)
end

*(x::PowerNumber, y::Number) = PowerNumber(y*apart(x),y*bpart(x),alpha(x),beta(x))
*(y::Number, x::PowerNumber) = *(x::PowerNumber, y::Number)

-(x::PowerNumber) = PowerNumber(-apart(x),-bpart(x),alpha(x),beta(x))
-(x::PowerNumber, y::PowerNumber) = +(x, -y)
-(x::PowerNumber, y::Number) = +(x::PowerNumber, -y::Number)
-(y::Number, x::PowerNumber) = +(-x::PowerNumber, y::Number)

function inv(x::PowerNumber)
    a,b,α,β = apart(x),bpart(x),alpha(x),beta(x)
    a != 0 ? PowerNumber(1/a,-b*a^(-2),-α,β-2*α) : PowerNumber(1/b,-β)
end

/(z::PowerNumber, x::PowerNumber) = z*inv(x)
/(z::PowerNumber, x::Number) = z*inv(x)
/(x::Number, z::PowerNumber) = x*inv(z)

^(z::PowerNumber, p::Integer) = invoke(^, Tuple{Number,Integer}, z, p)
function ^(z::PowerNumber, p::Number)
    a,b,α,β = apart(z),bpart(z),alpha(z),beta(z)
    a == 0 ? PowerNumber(b^p,β*p) :
    PowerNumber(a^p,(a^(p-1))*b*p,p*α,β+(p-1)*α)
end

sqrt(z::PowerNumber) = z^0.5
cbrt(z::PowerNumber) = z^(1/3)

==(a::PowerNumber, b::PowerNumber) = apart(a) == apart(b) && bpart(a) == bpart(b) && 
                                    alpha(a) == alpha(b) && beta(a) == beta(b)

isapprox(a::PowerNumber, b::PowerNumber; opts...) = ≈(apart(a), apart(b); opts...) && ≈(bpart(a), bpart(b); opts...) && 
                                                ≈(alpha(a), alpha(b); opts...) && ≈(beta(a), beta(b); opts...)

function log(z::PowerNumber)
    a,b,α,β = apart(z),bpart(z),alpha(z),beta(z)
    a ≈ 0 ? (b ≈ 0 ? error("Cannot evaluate log at 0") : return LogNumber(β, log(Complex(b)))) : return LogNumber(α, log(Complex(a)))
end

log1p(z::PowerNumber) = log(z+1)

function atanh(z::PowerNumber)
    (log(1+z)-log(1-z))/2
end

for op in (:real, :imag, :conj)
    @eval $op(l::PowerNumber) = PowerNumber($op(apart(l)), $op(bpart(l)), alpha(l), beta(l))
end

functionlist = (:abs2, :log10, :log2, :exp, :exp2, :expm1, 
:sin, :cos, :tan, :sec, :csc, :cot, :sind, :cosd, :tand, :secd, :cscd, :cotd, :asin, :acos, 
:atan, :asec, :acsc, :acot, :asind, :acosd, :atand, :asecd, :acscd, :acotd, :sinh, :cosh, 
:tanh, :sech, :csch, :coth, :asinh, :acosh, :asech, :acsch, :acoth, :deg2rad, :rad2deg)

for op in functionlist
    @eval function $op(z::PowerNumber)
        a,b,α,β = apart(z),bpart(z),alpha(z),beta(z)
        if α == 0 || a == 0
            fz = $op(dual(a,b))
            p = β
        elseif α > 0
            fz = $op(dual(0,a))
            p = α
        else
            error("Alpha must be non-negative")
        end
	    PowerNumber(realpart(fz), epsilon(fz), 0, p)
	end
end

#=
#speciallog(x::PowerNumber{<:Complex}) = alpha(x) == 1.0 ? (s = sqrt(x); 3(atanh(s)-realpart(s))/realpart(s)^3) : error("Only implemented for alpha = 1")

# function SingularIntegralEquations.HypergeometricFunctions.speciallog(x::PowerNumber)
#     s = sqrt(x)
#     return 3(atanh(s)-realpart(s))/realpart(s)^3
# end
=#
Base.show(io::IO, x::PowerNumber) = print(io, "($(x.A))ε^$(x.α) + ($(x.B))ε^$(x.β)")

end # module
