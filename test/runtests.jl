using PowerNumbers, Test, IntervalArithmetic, HypergeometricFunctions
import PowerNumbers: PowerNumber, LogNumber, realpart, apart, bpart, alpha, beta

@testset "RiemannDual -> PowerNumber" begin
    for h in (0.1,0.01), a in (2exp(0.1im),1.1)
        @test log(PowerNumber(0,a,0,1))(h) ≈ log(h*a)
        @test log(PowerNumber(a,Inf,-1,0))(h) ≈ log(a/h)
    end

    for h in (0.1,0.01), a in (2exp(0.1im),1.1)
        @test log1p(PowerNumber(-1,a,0,1))(h) ≈ log(h*a)
        @test log1p(PowerNumber(a,Inf,-1,0))(h) ≈ log(a/h)
    end

    h=0.0001
    for z in (PowerNumber(1,3exp(0.2im),0,1), PowerNumber(1,0.5exp(-1.3im),0,1),
              PowerNumber(-1,3exp(0.2im),0,1), PowerNumber(-1,0.5exp(-1.3im),0,1),
              PowerNumber(-1,1,0,1), PowerNumber(1,-1,0,1))
        @test atanh(z)(h) ≈  atanh(apart(z)*h^alpha(z)+bpart(z)*h^beta(z)) atol = 1E-4
    end

    #z = PowerNumber(1,-0.25,1)
    h = 0.0000001
    #@test speciallog(z)(h) ≈ speciallog(realpart(z)+epsilon(z)*h^alpha(z)) atol=1E-4

    z = PowerNumber(1,2,0,1)
    @test 1/(1-z(h)) ≈ (1/(1-z))(h) rtol=0.0001

    @test real(LogNumber(2im,im+1)) == LogNumber(0,1)
    @test imag(LogNumber(2im,im+1)) == LogNumber(2,1)
    @test conj(LogNumber(2im,im+1)) == LogNumber(-2im,1-im)

end

@testset "PowerNumbers arithmetic" begin
    h = 0.000000001
    @test inv(PowerNumber(1.0,2.0,-1/2,0))(h) ≈ inv(h^(-1/2) + 2) rtol = 0.001
    @test inv(PowerNumber(0.0,1.0,0,1/2))(h) ≈ inv(h^(1/2)) rtol = 0.001
    @test inv(PowerNumber(2.0,1.0,0,1/2))(h) ≈ inv(h^(1/2)+2) rtol = 0.001

    @test real(PowerNumber(2im,im+1,0,0.5)) == PowerNumber(0,1,0,0.5)
    @test imag(PowerNumber(2im,im+1,0,0.5)) == PowerNumber(2,1,0,0.5)
    @test conj(PowerNumber(2im,im+1,0,0.5)) == PowerNumber(-2im,1-im,0,0.5)

    @test (3*PowerNumber(0.01+3im,0.2im+1,0,0.4) - 4*PowerNumber(0.6-1.5im,1.5-0.3im,0,0.4))/3 == PowerNumber(-0.79+5.0im,-1.0 + 0.6im,0,0.4)
end

@testset "sin" begin
    ε = PowerNumber(1,1)
    @test sin(sqrt(ε))^2 === PowerNumber(1.0,1.0)
    @test sin(sqrt(ε))^2.0 === PowerNumber(1.0,1.0)
    @test sin(ε)/ε === PowerNumber(1.0,0.0,0,0)
    @test sin(sqrt(ε))/sqrt(ε) === PowerNumber(1.0,0.0,0.0,0.0)
end

@testset "LogNumber" begin
    ε = PowerNumber(1.0,1.0)
    z = 1-ε
    @test log1p(-z) isa LogNumber
    @test exp(LogNumber(2,3)) == exp(3)*ε^2
    HypergeometricFunctions.expm1(LogNumber(2,3))
end

@testset "Rational" begin
    ε = PowerNumber(1.0,1.0)
    @test PowerNumber(1.,0,0.,1.) + PowerNumber(-1.,0,2.,2.) == PowerNumber(1.,0.,0.,1)
    @test_broken (1 + 1/ε + 1/ε^2) / (1 + 1/ε + 1/ε^2) == 1
end

@testset "HypergeometricFunctions" begin
    a,b,c = 1.154,1.2543,1.3543345
    ε = PowerNumber(1.0,1.0)
    z = 1-ε
    _₂F₁(a,b,c,z)

    a,b,c = 1.1,1.2,1.3
    @test_broken _₂F₁(a,b,c,z)
    log1p(-z)
end

@testset "IntervalArithmetic" begin
    a = @interval(1.0)
    p = PowerNumber(a,a,0,1)
    @test (a^4+a^2-a) == (p^4+p^2-p)(0)
end



#0.19999999999999996, 0.10000000000000009, 1.3, 1.0 + (-1.0)ϵ^1.0 + o(ϵ^1.0)
#(HypergeometricFunctions._₂F₁general)(0.10000000000000009, 0.19999999999999996, 1.3, 1.0 + (-1.0)ϵ^1.0 + o(ϵ^1.0))
#(HypergeometricFunctions._₂F₁Inf)(0.10000000000000009, 1.1, 1.3, (-1.0)ϵ^-1.0 + (1.0)ϵ^0.0 + o(ϵ^0.0))
#(HypergeometricFunctions.AInf)(0.10000000000000009, 1.1, 1.3, (-1.0)ϵ^1.0 + (-1.0)ϵ^2.0 + o(ϵ^2.0), 1, 0.0)
#z = (-1.0)ϵ^1.0 + (-1.0)ϵ^2.0 + o(ϵ^2.0)
# z = PowerNumber(-1.,-1.,1.,2.)
# @enter (HypergeometricFunctions.BInf)(0.10000000000000009, 1.1, 1.3, z, 1, 0.0)
# @enter (HypergeometricFunctions.recInfβ₀)(0.10000000000000009, 1.1, 1.3, z, 1, 0.0)
