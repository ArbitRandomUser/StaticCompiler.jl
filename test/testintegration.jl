# Setup
testpath = pwd()
scratch = tempdir()
cd(scratch)

@testset "Standalone Executable Integration" begin

    jlpath = joinpath(Sys.BINDIR, Base.julia_exename()) # Get path to julia executable

    ## --- Times table, file IO, mallocarray
    let
        # Attempt to compile
        # We have to start a new Julia process to get around the fact that Pkg.test
        # disables `@inbounds`, but ironically we can use `--compile=min` to make that
        # faster.
        status = -1
        try
            isfile("times_table") && rm("times_table")
            status = run(`$jlpath --startup=no --compile=min $testpath/scripts/times_table.jl`)
        catch e
            @warn "Could not compile $testpath/scripts/times_table.jl"
            println(e)
        end
        @test isa(status, Base.Process)
        @test isa(status, Base.Process) && status.exitcode == 0

        # Attempt to run
        println("5x5 times table:")
        status = -1
        try
            status = run(`./times_table 5 5`)
        catch e
            @warn "Could not run $(scratch)/times_table"
            println(e)
        end
        @test isa(status, Base.Process)
        @test isa(status, Base.Process) && status.exitcode == 0
        # Test ascii output
        # @test parsedlm(Int, c"table.tsv", '\t') == (1:5)*(1:5)' broken=Sys.isapple()
        # Test binary output
        @test fread!(szeros(Int, 5,5), c"table.b") == (1:5)*(1:5)'
    end

    ## --- "withmallocarray"-type do-block pattern
    let
        # Compile...
        status = -1
        try
            isfile("withmallocarray") && rm("withmallocarray")
            status = run(`$jlpath --startup=no --compile=min $testpath/scripts/withmallocarray.jl`)
        catch e
            @warn "Could not compile $testpath/scripts/withmallocarray.jl"
            println(e)
        end
        @test isa(status, Base.Process)
        @test isa(status, Base.Process) && status.exitcode == 0

        # Run...
        println("3x3 malloc arrays via do-block syntax:")
        status = -1
        try
            status = run(`./withmallocarray 3 3`)
        catch e
            @warn "Could not run $(scratch)/withmallocarray"
            println(e)
        end
        @test isa(status, Base.Process)
        @test isa(status, Base.Process) && status.exitcode == 0
    end

    ## --- Random number generation
    let
        # Compile...
        status = -1
        try
            isfile("rand_matrix") && rm("rand_matrix")
            status = run(`$jlpath --startup=no --compile=min $testpath/scripts/rand_matrix.jl`)
        catch e
            @warn "Could not compile $testpath/scripts/rand_matrix.jl"
            println(e)
        end
        @test isa(status, Base.Process)
        @test isa(status, Base.Process) && status.exitcode == 0

        # Run...
        println("5x5 uniform random matrix:")
        status = -1
        try
            status = run(`./rand_matrix 5 5`)
        catch e
            @warn "Could not run $(scratch)/rand_matrix"
            println(e)
        end
        @test isa(status, Base.Process)
        @test isa(status, Base.Process) && status.exitcode == 0
    end

    let
        # Compile...
        status = -1
        try
            isfile("randn_matrix") && rm("randn_matrix")
            status = run(`$jlpath --startup=no --compile=min $testpath/scripts/randn_matrix.jl`)
        catch e
            @warn "Could not compile $testpath/scripts/randn_matrix.jl"
            println(e)
        end
        @static if Sys.isbsd()
            @test isa(status, Base.Process)
            @test isa(status, Base.Process) && status.exitcode == 0
        end

        # Run...
        println("5x5 Normal random matrix:")
        status = -1
        try
            status = run(`./randn_matrix 5 5`)
        catch e
            @warn "Could not run $(scratch)/randn_matrix"
            println(e)
        end
        @static if Sys.isbsd()
            @test isa(status, Base.Process)
            @test isa(status, Base.Process) && status.exitcode == 0
        end
    end

    ## --- Test LoopVectorization integration
    @static if LoopVectorization.VectorizationBase.has_feature(Val{:x86_64_avx2})
        let
            # Compile...
            status = -1
            try
                isfile("loopvec_product") && rm("loopvec_product")
                status = run(`$jlpath --startup=no --compile=min $testpath/scripts/loopvec_product.jl`)
            catch e
                @warn "Could not compile $testpath/scripts/loopvec_product.jl"
                println(e)
            end
            @test isa(status, Base.Process)
            @test isa(status, Base.Process) && status.exitcode == 0

            # Run...
            println("10x10 table sum:")
            status = -1
            try
                status = run(`./loopvec_product 10 10`)
            catch e
                @warn "Could not run $(scratch)/loopvec_product"
                println(e)
            end
            @test isa(status, Base.Process)
            @test isa(status, Base.Process) && status.exitcode == 0
            # @test parsedlm(c"product.tsv",'\t')[] == 3025
        end
    end

    let
        # Compile...
        status = -1
        try
            isfile("loopvec_matrix") && rm("loopvec_matrix")
            status = run(`$jlpath --startup=no $testpath/scripts/loopvec_matrix.jl`)
        catch e
            @warn "Could not compile $testpath/scripts/loopvec_matrix.jl"
            println(e)
        end
        @test isa(status, Base.Process)
        @test isa(status, Base.Process) && status.exitcode == 0

        # Run...
        println("10x5 matrix product:")
        status = -1
        try
            status = run(`./loopvec_matrix 10 5`)
        catch e
            @warn "Could not run $(scratch)/loopvec_matrix"
            println(e)
        end
        @test isa(status, Base.Process)
        @test isa(status, Base.Process) && status.exitcode == 0
        A = (1:10) * (1:5)'
        # Check ascii output
        # @test parsedlm(c"table.tsv",'\t') == A' * A broken=Sys.isapple()
        # Check binary output
        @test fread!(szeros(5,5), c"table.b") == A' * A
    end

    let
        # Compile...
        status = -1
        try
            isfile("loopvec_matrix_stack") && rm("loopvec_matrix_stack")
            status = run(`$jlpath --startup=no  $testpath/scripts/loopvec_matrix_stack.jl`)
        catch e
            @warn "Could not compile $testpath/scripts/loopvec_matrix_stack.jl"
            println(e)
        end
        @test isa(status, Base.Process)
        @test isa(status, Base.Process) && status.exitcode == 0

        # Run...
        println("10x5 matrix product:")
        status = -1
        try
            status = run(`./loopvec_matrix_stack`)
        catch e
            @warn "Could not run $(scratch)/loopvec_matrix_stack"
            println(e)
        end
        @test isa(status, Base.Process)
        @test isa(status, Base.Process) && status.exitcode == 0
        A = (1:10) * (1:5)'
        # @test parsedlm(c"table.tsv",'\t') == A' * A broken=Sys.isapple()
    end


    ## --- Test string handling

    let
        # Compile...
        status = -1
        try
            isfile("print_args") && rm("print_args")
            status = run(`$jlpath --startup=no --compile=min $testpath/scripts/print_args.jl`)
        catch e
            @warn "Could not compile $testpath/scripts/print_args.jl"
            println(e)
        end
        @test isa(status, Base.Process)
        @test isa(status, Base.Process) && status.exitcode == 0

        # Run...
        println("String indexing and handling:")
        status = -1
        try
            status = run(`./print_args foo bar`)
        catch e
            @warn "Could not run $(scratch)/print_args"
            println(e)
        end
        @test isa(status, Base.Process)
        @test isa(status, Base.Process) && status.exitcode == 0
    end

    ## --- Test error throwing

    let
        # Compile...
        status = -1
        try
            isfile("maybe_throw") && rm("maybe_throw")
            status = run(`$jlpath --startup=no --compile=min $testpath/scripts/throw_errors.jl`)
        catch e
            @warn "Could not compile $testpath/scripts/throw_errors.jl"
            println(e)
        end
        @test isa(status, Base.Process)
        @test isa(status, Base.Process) && status.exitcode == 0

        # Run...
        println("Error handling:")
        status = -1
        try
            status = run(`./maybe_throw 10`)
        catch e
            @warn "Could not run $(scratch)/maybe_throw"
            println(e)
        end
        @test isa(status, Base.Process)
        @test isa(status, Base.Process) && status.exitcode == 0
        status = -1
        try
            status = run(`./maybe_throw -10`)
        catch e
            @info "maybe_throw: task failed sucessfully!"
        end
        @test status === -1
    end

    ## --- Test interop

    @static if Sys.isbsd()
    let
        # Compile...
        status = -1
        try
            isfile("interop") && rm("interop")
            status = run(`$jlpath --startup=no --compile=min $testpath/scripts/interop.jl`)
        catch e
            @warn "Could not compile $testpath/scripts/interop.jl"
            println(e)
        end
        @test isa(status, Base.Process)
        @test isa(status, Base.Process) && status.exitcode == 0

        # Run...
        println("Interop:")
        status = -1
        try
            status = run(`./interop`)
        catch e
            @warn "Could not run $(scratch)/interop"
            println(e)
        end
        @test isa(status, Base.Process)
        @test isa(status, Base.Process) && status.exitcode == 0
    end
    end

end

# Mixtape

module SubFoo

function f()
    x = rand()
    y = rand()
    return x + y
end

function stringfun(s1, s2)
    return s1 * s2
end

function teststring()
    return stringfun("ab", "c") == "abc"
end

end

struct MyMix <: CompilationContext end

@testset "Mixtape" begin
    # 101: How2Mix

    # A few little utility functions for working with Expr instances.
    swap(e) = e
    function swap(e::Expr)
        new = MacroTools.postwalk(e) do s
            isexpr(s, :call) || return s
            s.args[1] == Base.rand || return s
            return 4
        end
        return new
    end

    # This is pre-inference - you get to see a CodeInfoTools.Builder instance.
    function StaticCompiler.transform(::MyMix, src)
        b = CodeInfoTools.Builder(src)
        for (v, st) in b
            b[v] = swap(st)
        end
        return CodeInfoTools.finish(b)
    end

    # MyMix will only transform functions which you explicitly allow.
    # You can also greenlight modules.
    StaticCompiler.allow(ctx::MyMix, m::Module) = m == SubFoo

    _, path = compile(SubFoo.f, (), mixtape = MyMix())
    @test load_function(path)() == 8
    @test SubFoo.f() != 8

    # redefine swap to test caching and add StaticString substitution
    function swap(e::Expr)
        new = MacroTools.postwalk(e) do s
            s isa String && return StaticTools.StaticString(tuple(codeunits(s)..., 0x00))
            isexpr(s, :call) || return s
            s.args[1] == Base.rand || return s
            return 2
        end
        return new
    end
    _, path = compile(SubFoo.f, (), mixtape = MyMix())
    @test load_function(path)() == 4

    _, path = compile(SubFoo.teststring, (), mixtape = MyMix())
    @test load_function(path)()

end

@testset "Cross compiling to WebAssembly" begin
    testpath = pwd()
    scratch = tempdir()
    cd(scratch)

    m2(x) = 2x
    m3(x) = 3x
    wasm_path = compile_wasm(m2, Tuple{Float64})
    wasm_path2 = compile_wasm([(m2, Tuple{Float64}), (m3, Tuple{Float64})])

    wasm_path = compile_wasm(m2, (Float64,))
    wasm_path2 = compile_wasm([(m2, (Float64,)), (m3, (Float64,))])

end

## --- Clean up

cd(testpath)
