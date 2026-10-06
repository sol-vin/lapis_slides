import json

def generate_custom_benchmarks_cast(output_path="casts/lapis_custom_benchmarks.cast"):
    events = []
    events.append([0.05, "o", "\x1b[2J\x1b[H\x1b[?25h"])
    prompt = "\x1b[1;32mian@workstation\x1b[0m:\x1b[1;34m~/lapis/template\x1b[0m$ "
    
    t = 0.2
    
    def type_cmd(start_t, p, cmd):
        cur = start_t
        events.append([round(cur, 3), "o", p])
        cur += 0.25
        for ch in cmd:
            cur += 0.028
            events.append([round(cur, 3), "o", ch])
        cur += 0.18
        events.append([round(cur, 3), "o", "\r\n"])
        return round(cur, 3)

    # =========================================================================
    # SCENE 1: Discovering Registered Benchmarks & Groups (lapis benchmarks -l)
    # =========================================================================
    t = type_cmd(t, prompt, "lapis benchmarks -l")
    t += 0.15
    
    scene1_out = (
        "\r\n\x1b[1;37mRegistered Benchmarks in ~/lapis/template/benchmarks (5 total):\x1b[0m\r\n"
        "  \x1b[1;36mPathfindingCrowd\x1b[0m     \x1b[33m[Group: Engine ]\x1b[0m A* routing throughput (5,000 active agents)\r\n"
        "    \x1b[90m•\x1b[0m \x1b[32mCrystal (AVX2 SIMD)\x1b[0m  \x1b[90m•\x1b[0m \x1b[37mGDScript (Baseline)\x1b[0m\r\n"
        "  \x1b[1;36mProceduralDungeon\x1b[0m    \x1b[35m[Custom: Compute]\x1b[0m BSP room partitioning & corridor generator\r\n"
        "  \x1b[1;36mCombatRadarScan\x1b[0m      \x1b[33m[Custom: Engine ]\x1b[0m QuadTree spatial query (1,200 entities)\r\n"
        "  \x1b[1;36mParticleBatchSim\x1b[0m     \x1b[35m[Custom: Compute]\x1b[0m 20,000 Verlet integration physics steps\r\n"
        "  \x1b[1;36mInventoryPacker\x1b[0m      \x1b[34m[Custom: Systems]\x1b[0m Binary buffer serialization & delta sync\r\n"
    )
    events.append([round(t, 3), "o", scene1_out])
    t += 4.2

    # =========================================================================
    # SCENE 2: Running Group with AVX2 SIMD & Latency Comparison Table
    # =========================================================================
    events.append([round(t, 3), "o", "\x1b[2J\x1b[H"])
    t += 0.1
    t = type_cmd(t, prompt, "lapis benchmarks run -g PathfindingCrowd --chart --html")
    t += 0.15

    # Compilation step
    events.append([round(t, 3), "o", "\x1b[36m[Benchmarks:Build]\x1b[0m Compiling benchmark harness with AVX2 SIMD (-O3 -s)...\r\n"])
    t += 0.4
    events.append([round(t, 3), "o", "  \x1b[32m✔\x1b[0m Harness compiled in 0.88s (\x1b[1mAVX2 SIMD vectorization active\x1b[0m)\r\n"])
    t += 0.3

    # Warmup step
    events.append([round(t, 3), "o", "\x1b[33m[Benchmarks:Warmup]\x1b[0m Priming JIT cache & worker fiber pool (10 iterations)...\r\n"])
    t += 0.35
    events.append([round(t, 3), "o", "  \x1b[32m✔\x1b[0m Warmup complete • Memory pool pinned\r\n"])
    t += 0.3

    # Run step with progress bar
    events.append([round(t, 3), "o", "\x1b[35m[Benchmarks:Run]\x1b[0m Profiling 'PathfindingCrowd' (5,000 active agents)...\r\n"])
    t += 0.2
    
    # Progress animation
    steps = [
        (25, "Iter 3/12 (15k samples)"),
        (50, "Iter 6/12 (30k samples)"),
        (75, "Iter 9/12 (45k samples)"),
        (100, "Iter 12/12 (60k samples)"),
    ]
    for pct, label in steps:
        bar_fill = "█" * (pct // 5)
        bar_empty = "░" * (20 - (pct // 5))
        line = f"\r\x1b[2K  Executing iterations [\x1b[36m{bar_fill}\x1b[90m{bar_empty}\x1b[0m] \x1b[1m{pct}%\x1b[0m {label}"
        events.append([round(t, 3), "o", line])
        t += 0.32
    
    events.append([round(t, 3), "o", "\r\n\r\n"])
    t += 0.2

    # Comparative Results Table
    table_out = (
        "\x1b[1;37mBenchmark Results: PathfindingCrowd (5,000 Agents)\x1b[0m\r\n"
        "\x1b[36m┌──────────────────────────────┬─────────────┬──────────────┬───────────┐\x1b[0m\r\n"
        "\x1b[36m│\x1b[0m \x1b[1mImplementation\x1b[0m               \x1b[36m│\x1b[0m \x1b[1mMedian Time\x1b[0m \x1b[36m│\x1b[0m \x1b[1mThroughput\x1b[0m   \x1b[36m│\x1b[0m \x1b[1mSpeedup\x1b[0m   \x1b[36m│\x1b[0m\r\n"
        "\x1b[36m├──────────────────────────────┼─────────────┼──────────────┼───────────┤\x1b[0m\r\n"
        "\x1b[36m│\x1b[0m \x1b[1;32mCrystal (SIMD AVX2)\x1b[0m          \x1b[36m│\x1b[0m     \x1b[32m0.82 ms\x1b[0m \x1b[36m│\x1b[0m 6,097 agt/fr \x1b[36m│\x1b[0m \x1b[1;32m15.4x 🚀\x1b[0m  \x1b[36m│\x1b[0m\r\n"
        "\x1b[36m│\x1b[0m GDScript (Baseline)          \x1b[36m│\x1b[0m    12.63 ms \x1b[36m│\x1b[0m   395 agt/fr \x1b[36m│\x1b[0m 1.0x (ref) \x1b[36m│\x1b[0m\r\n"
        "\x1b[36m└──────────────────────────────┴─────────────┴──────────────┴───────────┘\x1b[0m\r\n"
        "  \x1b[1mGeoMean Speedup:\x1b[0m  \x1b[1;36m15.4x faster\x1b[0m (Crystal vs GDScript)\r\n"
        "  \x1b[1mHeap Allocation:\x1b[0m  \x1b[1;32m0 bytes/frame\x1b[0m (Zero-Alloc Invariant Verified)\r\n"
    )
    events.append([round(t, 3), "o", table_out])
    t += 5.5

    # =========================================================================
    # SCENE 3: Running Compute Suite & Terminal ASCII/ANSI Bar Chart
    # =========================================================================
    events.append([round(t, 3), "o", "\x1b[2J\x1b[H"])
    t += 0.1
    t = type_cmd(t, prompt, "lapis benchmarks run -c compute --chart")
    t += 0.2

    scene3_out = (
        "\r\n\x1b[1;37m=== Lapis Benchmark Suite: Category 'compute' (4 cases) ===\x1b[0m\r\n"
        "  \x1b[32m✔\x1b[0m \x1b[1mParticleBatchSim\x1b[0m     (20k particles)   \x1b[32m2.15 ms\x1b[0m  (GDScript: 38.70 ms) -> \x1b[1;32m18.0x\x1b[0m\r\n"
        "  \x1b[32m✔\x1b[0m \x1b[1mProceduralDungeon\x1b[0m    (BSP 50 rooms)    \x1b[32m1.42 ms\x1b[0m  (GDScript: 24.10 ms) -> \x1b[1;32m17.0x\x1b[0m\r\n"
        "  \x1b[32m✔\x1b[0m \x1b[1mCombatRadarScan\x1b[0m      (1.2k entities)   \x1b[32m0.38 ms\x1b[0m  (GDScript:  5.89 ms) -> \x1b[1;32m15.5x\x1b[0m\r\n"
        "  \x1b[32m✔\x1b[0m \x1b[1mPathfindingCrowd\x1b[0m     (5k agents)       \x1b[32m0.82 ms\x1b[0m  (GDScript: 12.63 ms) -> \x1b[1;32m15.4x\x1b[0m\r\n"
        "\r\n"
        "  \x1b[1;36m📊 Speedup Factor (x) - Higher is Faster:\x1b[0m\r\n"
        "  ParticleBatchSim    [\x1b[36m██████████████████████████████████████████\x1b[0m] \x1b[1;32m18.0x\x1b[0m\r\n"
        "  ProceduralDungeon   [\x1b[36m██████████████████████████████████████    \x1b[0m] \x1b[1;32m17.0x\x1b[0m\r\n"
        "  CombatRadarScan     [\x1b[36m████████████████████████████████          \x1b[0m] \x1b[1;32m15.5x\x1b[0m\r\n"
        "  PathfindingCrowd    [\x1b[36m████████████████████████████████          \x1b[0m] \x1b[1;32m15.4x\x1b[0m\r\n"
        "\r\n"
        "  \x1b[1mGeoMean Speedup:\x1b[0m  \x1b[1;36m16.4x faster\x1b[0m across compute suite\r\n"
        "  \x1b[32m✔\x1b[0m Saved SVG chart: \x1b[36mreports/benchmarks/benchmark_chart.svg\x1b[0m\r\n"
        "  \x1b[32m✔\x1b[0m HTML Report:     \x1b[36mreports/benchmarks/benchmark_report.html\x1b[0m\r\n"
    )
    events.append([round(t, 3), "o", scene3_out])
    t += 5.5

    # Clean exit back to prompt
    events.append([round(t, 3), "o", prompt])
    t += 3.0
    events.append([round(t, 3), "o", ""])

    with open(output_path, "w", encoding="utf-8") as f:
        header = {
            "version": 2,
            "width": 86,
            "height": 22,
            "timestamp": 1790904120,
            "title": "Lapis Custom Benchmarks: PathfindingCrowd & Compute Suite",
            "env": {"TERM": "xterm-256color", "SHELL": "lapis"}
        }
        f.write(json.dumps(header) + "\n")
        for ev in events:
            f.write(json.dumps(ev) + "\n")
            
    print(f"Generated {output_path} successfully ({len(events)} events, duration: {round(t, 1)}s)")

if __name__ == "__main__":
    generate_custom_benchmarks_cast()
