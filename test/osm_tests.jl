using LightOSM

@testset "OpenStreetMap space" begin
    space = OpenStreetMapSpace(OSM.OSM_test_map())
    @test length(space.s) == 20521
    @test sprint(show, space) ==
          "OpenStreetMapSpace with 1456 ways and 20521 nodes"

    Random.seed!(689)
    model = ABM(Agent10, space)

    @test OSM.random_road_position(model) != OSM.random_road_position(model)
    intersection = random_position(model)
    @test intersection[1] == intersection[2]
    @test intersection[3] == 0.0
    ll = OSM.latlon(intersection, model)
    @test intersection == OSM.intersection(ll, model)

    start_latlon = (51.5328328, 9.9351811)
    start_i = OSM.intersection(start_latlon, model)
    i_diff = sum(abs.(OSM.latlon(start_i, model) .- start_latlon))
    start_r = OSM.road(start_latlon, model)
    r_diff = sum(abs.(OSM.latlon(start_r, model) .- start_latlon))
    @test i_diff >= r_diff

    finish_latlon = (51.53530349140799, 9.939184637154902)
    finish_i = OSM.intersection(finish_latlon, model)
    finish_r = OSM.road(finish_latlon, model)

    add_agent!(start_r, model)
    OSM.plan_route!(model[1], finish_r, model)
    @test length(model.space.routes[1].route) == 52
    add_agent!(finish_i, model)

    @test OSM.latlon(model[2], model) == OSM.latlon(finish_i[1], model)
    np = nearby_positions(model[2], model)
    @test length(np) == 3
    @test all(OSM.latlon(np[1], model) .≈ (51.535028, 9.9393778))

    rand_road = OSM.random_road_position(model)
    rand_intersection = random_position(model)
    move_agent!(model[2], rand_road, model)
    OSM.plan_route!(model[2], rand_intersection, model; return_trip = true)
    @test length(model.space.routes[2].route) == 357

    @test OSM.road_length(model[1].pos, model) ≈ 0.00011942893648990791
    @test OSM.road_length(finish_r[1], finish_r[2], model) ≈ 0.0006626492380229374

    @test length(OSM.plan_route(start_r[2], finish_r[1], model)) == 22
    @test length(OSM.plan_route(start_r, finish_r[1], model)) == 21
    @test length(OSM.plan_route(start_r[2], finish_r, model)) == 21
    @test OSM.plan_route(start_r, finish_r[1], model) !=
          OSM.plan_route(start_r[2], finish_r, model)
    @test length(OSM.plan_route(start_r, finish_r, model)) == 20

    @test OSM.map_coordinates(model[1], model) == (-2904.337825035879, 1444.5549163962387)
    @test OSM.map_coordinates(model[2], model) == (-1475.8022717621393, 461.34058791100955)

    @test !is_stationary(model[1], model)
    move_along_route!(model[1], model, 403.2)
    @test length(model[1].route) == 16
    move_along_route!(model[1], model, 1500)
    @test isempty(model[1].route)
    @test !is_stationary(model[1], model)
    move_along_route!(model[1], model, 200)
    @test !is_stationary(model[1], model)
    move_along_route!(model[1], model, 200)
    @test !is_stationary(model[1], model)
    move_along_route!(model[1], model, 200)
    @test is_stationary(model[1], model)

    @test is_stationary(model[2], model)
    @test move_along_route!(model[2], model, 50) === nothing

    add_agent!(start_r, model, route, finish_r)
    OSM.random_route!(model[3], model)
    @test model[3].destination != finish_r
    move_along_route!(model[3], model, 100.0)

    for i in 1:5
        s = (start_r[1:2]..., start_r[3] - i)
        route = OSM.plan_route(s, finish_r, model)
        add_agent!(s, model, route, finish_r)
    end

    @test sort!(nearby_ids(model[6], model, 2)) == [4, 5, 7, 8]
    @test sort!(nearby_ids(model[6], model, 800.0)) == [3, 4, 5, 7, 8]

    # Test long moves
    start = random_position(model)
    finish = OSM.random_road_position(model)
    route = OSM.plan_route(start, finish, model)
    long = add_agent!(start, model, route, finish)
    move_along_route!(long, model, 10^5)
    @test long.pos == long.destination
end
