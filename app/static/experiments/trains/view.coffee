bigCanvas = require("experiments/big-canvas")
sequence  = require("experiments/sequence")

pos = (dir) ->
  switch dir
    when 0 then {x: 1, y: 0}
    when 1 then {x: 1, y: 1}
    when 2 then {x: 0, y: 1}
    when 3 then {x: -1, y: 1}
    when 4 then {x: -1, y: 0}
    when 5 then {x: -1, y: -1}
    when 6 then {x: 0, y: -1}
    when 7 then {x: 1, y: -1}

module.exports =
  draw: (options, done) ->
    { canvas, ctx } = bigCanvas(options)

    scale = options.scale or 1

    options.distance *= scale

    canvas.width  *= scale
    canvas.height *= scale

    window.canvas = canvas
    window.ctx = ctx

    marg = 80
    size = Math.min(canvas.width, canvas.height)
    offX = marg + (canvas.width  - size) / 2
    offY = marg + (canvas.height - size) / 2

    bounds = [offX, offY, size - marg * 2, size - marg * 2]
    gridSize = 20

    # Filter
    # include = ["Central", "Redfern", "Macdonaldtown", "Newtown", "Stanmore", "Petersham", "Lewisham","Green Square","Mascot","Domestic Airport","International Airport","Wolli Creek"]

    # data.stations = data.stations.filter((s) ->
    #   _.include(include, s.Name)
    # )

    # data.lines = data.lines.filter((l) ->
    #   _.intersection(_.flatten(l.stations), include).length > 0
    # ).map((l) ->
    #   stations: _.intersection(_.flatten(l.stations), include)
    # )

    console.log data.lines

    lines = data.lines
    list = _.chain(lines).pluck("stations").flatten().uniq().value()
    stations = data.stations.filter (s) -> list.indexOf(s.Name) > -1
    links = []


    sequence [
      ->
        ctx.globalAlpha = 0.1
        ctx.beginPath()
        ctx.rect bounds...
        ctx.stroke()

      # Parse coordinates
      ->
        for station in stations
          if station.Coordinates
            [lat, lng] =
              station.Coordinates
                .match(/(\d{1,3}.\d{3,}°[SWEN] {0,1})/g)
                .slice(0,2)
                .map((e) -> +e.match(/[\d\.]+/)[0])

            station.lat = lat
            station.lng = lng

      # Get position
      ->
        minLat = _.min(stations, "lat").lat
        maxLat = _.max(stations, "lat").lat
        minLng = _.min(stations, "lng").lng
        maxLng = _.max(stations, "lng").lng

        distLat = maxLat - minLat
        distLng = maxLng - minLng
        dist = Math.max(distLat, distLng)

        for station in stations
          fx = (station.lng - minLng) / (distLng) * (bounds[2] - gridSize)
          fy = (station.lat - minLat) / (distLat) * (bounds[3] - gridSize)
          station.x = bounds[0] + fx
          station.y = bounds[1] + fy

          station.gx = bounds[0] + (Math.floor(fx / gridSize) + 0.5) * gridSize
          station.gy = bounds[1] + (Math.floor(fy / gridSize) + 0.5) * gridSize

      # Draw initial
      ->
        ctx.beginPath()
        ctx.fillStyle = "cyan"
        radius = 8

        ctx.globalAlpha = 0.5

        for station in stations
          ctx.moveTo station.x, station.y
          ctx.arc station.x, station.y, radius, 0, Math.PI * 2
          # ctx.fillText station.Name, station.x + radius * 2, station.y + 4

        ctx.fill()

        ctx.fillStyle = "red"
        ctx.beginPath()
        for station in stations
          ctx.moveTo station.gx, station.gy
          ctx.arc station.gx, station.gy, radius, 0, Math.PI * 2
          ctx.fillText station.Name, station.gx + radius * 2, station.gy + 4

        ctx.fill()

      # Draw netwrok
      ->
        list = lines
        ctx.beginPath()
        ctx.lineWidth = 3
        ctx.strokeStyle = "red"

        draw = (items, start, end) ->
          for line, i in items
            if start
              first = start
              rest = _.compact line.stations.concat(end)
            else
              [first, rest...] = line.stations

            station = _.find(stations, Name: first)
            ctx.moveTo station.gx, station.gy

            for next, j in rest
              if _.isArray(next)
                wrap = next.map((l) -> {stations: l})
                draw(wrap, rest[j - 1], rest[j + 1])
              else
                station = _.find(stations, Name: next)
                ctx.lineTo station.gx, station.gy

        draw(list)

        ctx.stroke()

      # Draw grid
      ->
        ctx.lineWidth = 0.25
        ctx.strokeStyle = "grey"
        ctx.beginPath()

        for row in [0...bounds[3] / gridSize]
          y = bounds[1] + row * gridSize
          ctx.moveTo(bounds[0], y)
          ctx.lineTo(bounds[0] + bounds[2], y)

          x = bounds[0] + row * gridSize
          ctx.moveTo(x, bounds[1])
          ctx.lineTo(x, bounds[1] + bounds[3])

        ctx.stroke()

      ->
        ctx.lineWidth = 4
        ctx.strokeStyle = "black"
        ctx.beginPath()
        radius = 8

        lists = lines.reduce (m, e, i) ->
          line = e.stations
          flat = _.flatten(line)
          forks = line.filter(_.isArray)

          list = line.reduce((memo, el, i) ->
            if _.isArray(el)
              f = _.last(_.last(memo))
              for part in el
                memo.push([f, part...])

            else
              _.last(memo).push(el)
            memo
          , [[]]
          ).filter((l) -> l.length > 1)

          for item in list
            m.push(item)

          m

        , []

        links = (lists.map(_.clone))
        flat  = _.pluck(lines, "stations").map(_.flatten)

        connections = _.countBy _.sortBy _.flatten lists

        for key, val of connections
          _.find(stations, Name: key).connections = val

        biggest = _.findKey connections, (e) -> e is _.max(connections)

        explore = (prev) ->

          available = stations.filter (e) -> not e.visited
          active = flat.filter (list) -> _.include(list, prev.Name)

          common = _.flatten(active)

          for list in lists
            if list.indexOf(prev.Name) > -1
              list.splice(list.indexOf(prev.Name), 1)
              curr = list
              break
            prev.visited = true

          if curr
            explore(prev)
          else if available.length
            next = _.last _.sortBy(available, "connections")
            explore(next)


        #   # console.log lists
        #   return
        #   nexts = _.without(available, prev)
        #     .filter((e) -> _.include(common, e.Name))
        #     .sort((a, b) ->
        #       ad = Math.pow(a.x - prev.x, 2) + Math.pow(a.y - prev.y, 2)
        #       bd = Math.pow(b.x - prev.x, 2) + Math.pow(b.y - prev.y, 2)
        #       ad - bd
        #     ).slice(0,1)

        #   if nexts.length
        #     steps = active.length
        #     dir = nexts.reduce((m, next) ->
        #       m + Math.atan2(next.y - prev.y, next.x - prev.x)
        #     , 0) / nexts.length

        #     dir = (dir + Math.PI * 2) if dir < 0

        #     dir = ~~(dir / (Math.PI * 2) * 8) % 8
        #     opp = (dir + 2) % 8

        #     console.log dir, opp
        #     pdir = pos(dir)
        #     popp = pos(opp)

        #     ctx.beginPath()
        #     ctx.strokeStyle = "red"

        #     px = popp.x * gridSize * (-steps/2)
        #     py = popp.y * gridSize * (-steps/2)
        #     ox = px + popp.x * gridSize * steps
        #     oy = py + popp.y * gridSize * steps
        #     ctx.moveTo prev.gx + px, prev.gy + py
        #     ctx.lineTo prev.gx + ox, prev.gy + oy

        #     for n in [0..steps]
        #       i = n - steps / 2
        #       px = popp.x * gridSize * i
        #       py = popp.y * gridSize * i
        #       ox = px + pdir.x * gridSize * 4
        #       oy = py + pdir.y * gridSize * 4

        #       ctx.moveTo prev.gx + px, prev.gy + py
        #       ctx.lineTo prev.gx + ox, prev.gy + oy

        #     ctx.stroke()

        #     nexts[0].gx = prev.gx + pdir.x * gridSize * 4
        #     nexts[0].gy = prev.gy + pdir.y * gridSize * 4

        #     explore(nexts[0])

        #   else if available.length
        #     explore available[0]

        # explore(_.find stations, Name: biggest)


      ->
        return
        nodes = stations.map (s, i) ->
          index: i
          id: s.Name
          x: s.gx
          y: s.gy
          dx: s.gx
          dy: s.gy
          r: gridSize

        links = lines.reduce (m, l) ->
          k = 0
          for target, i in l.stations.slice(1)
            source = l.stations[i]
            if _.isArray(target)
              for line in target
                first = l.stations[k + 1]
                list = [first].concat line
                for next, j in list.slice(1)
                  m.push { source: list[j], target: next }
            else
              k = i
              if _.isArray(source)
                for line in source
                  m.push { source: _.last(line), target }
              else
                m.push { source: source, target }

          m
        , []

        console.log nodes
        # return
        link = d3.forceLink(links).id((d) -> d.id).distance(gridSize).iterations(30)
        # console.log link
        console.log [bounds[0]+bounds[2]/2, bounds[1]+bounds[3]/2]
        ctx.globalAlpha = 1

        window.simulation = d3.forceSimulation()
          .nodes(nodes)
          # .force("x", d3.forceX((d) -> Math.floor(d.x / gridSize) * gridSize).strength(3) )
          # .force("y", d3.forceY((d) -> Math.floor(d.y / gridSize) * gridSize).strength(3) )
          .force("x", d3.forceX((d) -> d.dx).strength(0.08) )
          .force("y", d3.forceY((d) -> d.dy).strength(0.08) )
          # .force("collide", d3.forceCollide((d) -> -d.r))
          .force("charge", d3.forceManyBody().strength((d) -> -gridSize * 3))
          # .force("center", d3.forceCenter(canvas.width / 2, canvas.height / 2))
          .force("links", link)
          .on("tick", ->
            ctx.clearRect(0, 0, canvas.width, canvas.height)
            ctx.beginPath()
            console.log "tick"

            for node in nodes
              node.gx = node.x# = bounds[0] + Math.round((node.x - bounds[0]) / gridSize) * gridSize
              node.gy = node.y# = bounds[1] + Math.round((node.y - bounds[1]) / gridSize) * gridSize

              ctx.moveTo node.gx, node.gy
              ctx.arc node.gx, node.gy, 8, 0, Math.PI * 2
              ctx.fillText node.id, node.gx + 20, node.gy + 4

            ctx.fill()

            ctx.lineWidth = 1
            ctx.strokeStyle = "red"
            ctx.beginPath()

            for {source, target}, i in links
              ctx.moveTo source.gx, source.gy
              ctx.lineTo target.gx, target.gy

            ctx.stroke()

            ctx.lineWidth = 0.25
            ctx.strokeStyle = "grey"
            ctx.beginPath()

            for row in [0...bounds[3] / gridSize]
              y = bounds[1] + row * gridSize
              ctx.moveTo(bounds[0], y)
              ctx.lineTo(bounds[0] + bounds[2], y)

              x = bounds[0] + row * gridSize
              ctx.moveTo(x, bounds[1])
              ctx.lineTo(x, bounds[1] + bounds[3])

            ctx.stroke()
          )

      -> done canvas
    ]

