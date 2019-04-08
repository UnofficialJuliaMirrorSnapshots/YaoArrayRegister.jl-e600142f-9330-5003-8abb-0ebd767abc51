using Test, YaoBase, YaoArrayRegister, LinearAlgebra, LuxurySparse, SparseArrays

# NOTE: we don't have block here, feel safe to use
using YaoBase.Const

@testset "test general unitary instruction" begin
    U1 = randn(ComplexF64, 2, 2)
    ST = randn(ComplexF64, 1<<4)
    I2 = IMatrix(2)
    M = kron(I2, U1, I2, I2) * ST

    @test instruct!(copy(ST), U1, 3) ≈ M ≈
        instruct!(reshape(copy(ST), :, 1), U1, 3)

    U2 = rand(ComplexF64, 4, 4)
    M = kron(I2, U2, I2) * ST
    @test instruct!(copy(ST), U2, (2, 3)) ≈ M

    @test instruct!(copy(ST), kron(U1, U1), (3, 1)) ≈
        instruct!(instruct!(copy(ST), U1, 3), U1, 1)

    @test instruct!(reshape(copy(ST), :, 1), kron(U1, U1), (3, 1)) ≈
        instruct!(instruct!(reshape(copy(ST), :, 1), U1, 3), U1, 1)

    U2 = sprand(ComplexF64, 8, 8, 0.1)
    ST = randn(ComplexF64, 1<<5)
    M = kron(I2, U2, I2) * ST
    @test instruct!(copy(ST), U2, (2, 3, 4)) ≈ M

    @test instruct!(copy(ST), I2, (1, )) ≈ ST
end


@testset "test general control unitary operator" begin
    ST = randn(ComplexF64, 1<<5)
    U1 = randn(ComplexF64, 2,2)
    instruct!(copy(ST), U1, (3, ), (1, ), (1, ))

    @test instruct!(copy(ST), U1, (3, ), (1, ), (1, )) ≈
        general_controlled_gates(5, [P1], [1], [U1], [3]) * ST
    @test instruct!(copy(ST), U1, (3, ), (1, ), (0, )) ≈
        general_controlled_gates(5, [P0], [1], [U1], [3]) * ST

    # control U2
    U2 = kron(U1, U1)
    @test instruct!(copy(ST), U2, (3, 4), (1, ), (1, )) ≈
        general_controlled_gates(5, [P1], [1], [U2], [3]) * ST

    # multi-control U2
    @test instruct!(copy(ST), U2, (3, 4), (5, 1), (1, 0)) ≈
        general_controlled_gates(5, [P1, P0], [5, 1], [U2], [3]) * ST
end


@testset "test Pauli instructions" begin
    @testset "test $G instructions" for (G, M) in zip((:X, :Y, :Z), (X, Y, Z))
        @test linop2dense(s->instruct!(s, Val(G), (1, )), 1) == M
        @test linop2dense(s->instruct!(s, Val(G), (1, 2, 3)), 3) == kron(M, M, M)
    end

    @testset "test controlled $G instructions" for (G, M) in zip((:X, :Y, :Z), (X, Y, Z))
        @test linop2dense(s->instruct!(s, Val(G), 4, (2, 1), (0, 1)), 4) ≈
            general_controlled_gates(4, [P0, P1], [2, 1], [M], [4])

        @test linop2dense(s->instruct!(s, Val(G), 1, 2, 0), 2) ≈
            general_controlled_gates(2, [P0], [2], [M], [1])
    end
end

@testset "single qubit instruction" begin
    ST = randn(ComplexF64, 1 << 4)
    Pm = pmrand(ComplexF64, 2)
    Dv = Diagonal(randn(ComplexF64, 2))

    @test instruct!(copy(ST), Pm, 3) ≈ kron(I2, Pm, I2, I2) * ST ≈
        instruct!(reshape(copy(ST), :, 1), Pm, 3)
    @test instruct!(copy(ST), Dv, 3) ≈ kron(I2, Dv, I2, I2) * ST ≈
        instruct!(reshape(copy(ST), :, 1), Dv, 3)
end

@testset "swap instruction" begin
    ST = randn(ComplexF64, 1 << 2)
    @test instruct!(copy(ST), Val(:SWAP), (1, 2)) ≈ SWAP * ST
end