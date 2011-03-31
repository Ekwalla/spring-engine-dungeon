--[[
    filename	= "MazeCode",
    desc		= "Maze generation classes",
    author		= "CarRepairer",
    date		= "2011-03-24",
    license		= "GNU GPL, v2 or later",
--]]

local echo = Spring.Echo


---------- CLASS MazeMaster

MazeMaster = function() end;
do
	
    local function SetGrid(self)
        for x=1,self.width  do
            self.grid[x] = {}
            for y=1,self.height do
                self.grid[x][y] = self.bStr
            end
        end
    end
    local function SetSize(self, width, height)
        self.height = height
        self.width = width
        SetGrid(self)
    end
    
	local function GridToStringGrid(self, grid)
		local outgrid = grid
		local gwidth, gheight = #(outgrid), #(outgrid[1])
        local str = ''
		for x=1, gwidth do 
        	for y = 1,gheight do    
                outgrid[x][y] = tostring( grid[x][y] ) 
            end 
        end
		return outgrid
	end
	
    local function GridToString(self, rawgrid)
		local grid = GridToStringGrid(self, rawgrid)
        local gwidth, gheight = #(grid), #(grid[1])
        local str = ''
        for y = gheight, 1, -1  do
            local row = ''
            for x=1, gwidth do    
                row = row .. grid[x][y]
            end
            str = str .. row .. '\n'
        end
        return str
    end
	
	
	local function GetGrid(self)
		local outgrid = GridToStringGrid(self, self.grid)
		return outgrid
		
    end
    
    local function __tostring(self)
        return GridToString(self, self.grid )
    end
    
    local function GenerateMaze(self, type)
        local type = type
        if not type then
            type = 'random'
        end
        
        if type == 'random' then
            for i=1,17 do
                local x = math.random(1,self.width)
                local y = math.random(1,self.height)
                self.grid[x][y] = self.sStr
            end
        end
    end
	local function MakeEntrance(self, x,y)
		if not x then x = 2 end
		if not y then y = 1 end
		self.grid[x][y] = self.sStr
	end
	
    MazeMaster = function(height, width)
        if
            height < 5
            or width < 5
            or height % 2 ~= 1
            or width % 2 ~= 1
            then
            echo "<MazeMaster> ERROR! Height and width must be odd numbers greater than 4."
            return false
        end
        
        local self =
        {
            height      = height or 0,
            width       = width or 0,
            
            SetSize     = SetSize,
            __tostring      = __tostring,
            GenerateMaze   	= GenerateMaze,
            MakeEntrance   	= MakeEntrance,
            GetGrid   		= GetGrid,
            
            --feeble underscore of false protection
			grid        = {},
            GridToString = GridToString,
            bStr = 'X',
            sStr = ' ',
            dStr = 'D',
        }
        
        setmetatable(self, self)
        SetGrid(self)
        
        return self
    end--constr
end--do MazeMaster

---------- CLASS Cell

Cell = function() end
do
    local function __tostring(self)
        return self.sStr
    end

    Cell = function(sStr)
        local self =
        {
			sStr=sStr or '*',
            n=false,
            s=false,
            e=false,
            w=false,
			matched=false,
			--in=false,
            __tostring=__tostring,
        }
        
        setmetatable(self, self)
        return self
    end--constr
end

---------- Wall Cell

WallCell = function() end
do
    local function __tostring(self)
		return self.sStr
    end

    WallCell = function(sStr, dStr)
        local self =
        {
			sStr=sStr or '*',
			dStr=dStr or '+',
            n=false,	--north wall of cell
            e=false,	--east wall of cell
			door=false,
			--matched=false,
			--in=false,
			
            __tostring=__tostring,
        }
        
        setmetatable(self, self)
        return self
    end--constr
end


---------- CLASS MazeMasterCarver

MazeMasterCarver = function() end;
do
  
	local function MainGridToCellGrid(self)
		--echo 'MAIN GRID TO CELL'
		for x=1,self.cwidth  do
			self.cgrid[x] = {}
			for y=1,self.cheight do
				self.cgrid[x][y] = Cell(self.sStr)
			end
		end
	
	end

    local function ApplyCellGridOnMainGrid(self)
        for x=1,self.cwidth  do
            for y=1,self.cheight do
                self.grid[x*2][y*2] = self.cgrid[x][y]
            end
        end
    end
	
	local function CarveOutWalls(self)
		for x=1,self.width  do
			for y=1,self.height do
				local cell = self.grid[x][y]
				if cell.n then 	self.grid[x][y+1] = self.sStr;	end
				if cell.s then 	self.grid[x][y-1] = self.sStr;	end
				if cell.e then 	self.grid[x+1][y] = self.sStr;	end
				if cell.w then 	self.grid[x-1][y] = self.sStr;	end
			end	
		end
	end
    
    local function CellGridToMainGrid(self)
        ApplyCellGridOnMainGrid(self)
        CarveOutWalls(self)
    end
    
    -- [[
    local function CarveMaze(self)
        for i=1,1 do
            local x = math.random(1,self.cwidth)
            local y = math.random(1,self.cheight)
            self.cgrid[x][y].n = true
        end
    end
    --]]
	
	
    
    
    local function GenerateMaze(self, type)
        MainGridToCellGrid(self)
        
		--[[
        echo 'Test 1: this is the cellgrid\n'
        echo( self.GridToString(self, self.cgrid) )
        --]]
		
        self.CarveMaze(self)
        
		--[[
        echo 'Test 2: this is the cellgrid after carve\n'
        echo( self.GridToString(self, self.cgrid) )
        --]]
        
        CellGridToMainGrid(self)
        
        return 
    end
	
    local function RandomizeTable(t)
		local randTable = {}
		for i=1,#t do
			randTable[i]= {math.random(), i}
		end
		table.sort(randTable, function(a,b) return a[1] > b[1]; end )
		local newTable = {}
		for i=1,#t do
			newTable[i]= t[ randTable[i][2] ] 
		end
		return newTable
		
	end
	
    MazeMasterCarver = function(...)
        local self = MazeMaster(...)
		if not self then return false end
        
        self.cgrid = {}
        self.cheight = (self.height - 1) / 2
        self.cwidth = (self.width - 1) / 2
        self.GenerateMaze = GenerateMaze
		
		--feeble underscore of false protection
        self.CarveMaze = CarveMaze
        self.RandomizeTable = RandomizeTable
        
        
        return self
    end--constr
end--do MazeMasterCarver


---------- CLASS MazeMasterWallAdder

MazeMasterWallAdder = function() end;
do
  
	local function MainGridToCellGrid(self)
		--echo 'MAIN GRID TO CELL'
		for x=1,self.cwidth  do
			self.cgrid[x] = {}
			for y=1,self.cheight do
				self.cgrid[x][y] = WallCell(self.sStr, self.dStr)
			end
		end
	
	end

    local function ApplyCellGridOnMainGrid(self)
        for x=1,self.cwidth  do
            for y=1,self.cheight do
                self.grid[x*2][y*2] = self.cgrid[x][y]
            end
        end
    end
	
	local function IsOdd(num)
		return (num % 2) == 1
	end
	
	local function RemoveAllWalls(self)
		
		for x=2,self.width-1  do
			for y=2,self.height-1 do
				if not( IsOdd(x) and IsOdd(y) ) then
					self.grid[x][y] = self.sStr
				end
			end	
		end
	end
	
	
    
    local function AddWalls(self)
		for x=2,self.width-1  do
			for y=2,self.height-1 do
				local wcell = self.grid[x][y]
				if wcell.n then self.grid[x][y+1] = self.bStr end
				if wcell.e then self.grid[x+1][y] = self.bStr end
				
				if wcell.door_n then self.grid[x][y+1] = self.dStr end
				if wcell.door_e then self.grid[x+1][y] = self.dStr end
			end	
		end
	end
    
	local function RemoveLoneVerts(self)
		for x=2,self.width-1  do
			for y=2,self.height-1 do
				if
					self.grid[x+1][y] == self.sStr 
					and self.grid[x-1][y] == self.sStr 
					and self.grid[x][y+1] == self.sStr
					and self.grid[x][y-1] == self.sStr
					then
					self.grid[x][y] = self.sStr
				end
			end	
		end
	end
	
    local function CellGridToMainGrid(self)
		RemoveAllWalls(self)
        ApplyCellGridOnMainGrid(self)
		AddWalls(self)
		RemoveLoneVerts(self)
    end
    
    local function DrawMaze(self)
        for i=1,1 do
            local x = math.random(1,self.cwidth)
            local y = math.random(1,self.cheight)
            self.cgrid[x][y].n = true
        end
    end
    
    
    local function GenerateMaze(self, type)
        MainGridToCellGrid(self)
        self.DrawMaze(self)
        CellGridToMainGrid(self)
        return 
    end
	
    local function RandomizeTable(t)
		local randTable = {}
		for i=1,#t do
			randTable[i]= {math.random(), i}
		end
		table.sort(randTable, function(a,b) return a[1] > b[1]; end )
		local newTable = {}
		for i=1,#t do
			newTable[i]= t[ randTable[i][2] ] 
		end
		return newTable
		
	end
	
    MazeMasterWallAdder = function(...)
        local self = MazeMaster(...)
        if not self then return false end
		
        self.cgrid = {}
        self.cheight = (self.height - 1) / 2
        self.cwidth = (self.width - 1) / 2
        self.GenerateMaze = GenerateMaze
		
		--feeble underscore of false protection
        self.DrawMaze = DrawMaze
        self.RandomizeTable = RandomizeTable
        
        
        return self
    end--constr
end--do MazeMasterCarver


----------- CLASS MazeMasterRecBack 

MazeMasterRecBack = function() end;
do
	local N, S, E, W = 'n', 's', 'e', 'w'
	local DX = { [E] = 1, [W] = -1, [N] = 0, [S] = 0 }
	local DY = { [E] = 0, [W] = 0, [N] = 1, [S] = -1 }
	local OPPOSITE = { [E] = W, [W] = E, [N] = S, [S] = N }

	
	local directions = {N,S,E,W}
	
	
	
	local function CarvePassages(self, cx, cy)
		local randomDirs = self.RandomizeTable( directions )
		--local randomDirs = directions
		for _,direction in ipairs( randomDirs ) do
			
			local nx, ny = cx + DX[direction], cy + DY[direction]
			--echo ('TRY CARVE PASSAGE', direction, cx, cy, nx, ny)	
			if 	nx > 0 and nx <= self.cwidth
				and ny > 0 and ny <= self.cheight
				and (not self.cgrid[nx][ny].matched )
			then
				--echo ('CARVE PASSAGE', direction, cx, cy, nx, ny)	
				self.cgrid[cx][cy][direction] = true
				self.cgrid[nx][ny][ OPPOSITE[direction] ] = true
				
				self.cgrid[cx][cy].matched = true
				self.cgrid[nx][ny].matched = true
				
				CarvePassages(self, nx, ny)
			end
		end
		
	end
	
    local function CarveMaze(self)
		CarvePassages(self, 1,1)
    end
    
    
    
    MazeMasterRecBack = function(...)
        local self = MazeMasterCarver(...)
        if not self then return false end
		
        --todo, make this nicer
		self.CarveMaze = CarveMaze --override
        
        return self
    end--constr
end--do MazeMasterRecBack


---------- CLASS MazeMasterHuntKill 

MazeMasterHuntKill = function() end;
do
	local N, S, E, W = 'n', 's', 'e', 'w'
	local DX = { [E] = 1, [W] = -1, [N] = 0, [S] = 0 }
	local DY = { [E] = 0, [W] = 0, [N] = 1, [S] = -1 }
	local OPPOSITE = { [E] = W, [W] = E, [N] = S, [S] = N }

	
	local directions = {N,S,E,W}
	
	
	-- [[
	local function Walk(self, x, y)
		local randomDirs = self.RandomizeTable( directions )
		for _,dir in ipairs( randomDirs ) do
			local nx, ny = x + DX[dir], y + DY[dir]
			if nx > 0 and ny > 0
				and ny <= self.cheight and nx <= self.cwidth
				and (not self.cgrid[nx][ny].matched )
				then
				
				self.cgrid[x][y][ dir ] = true
				self.cgrid[nx][ny][ OPPOSITE[dir] ] = true
				
				self.cgrid[x][y].matched = true
				self.cgrid[nx][ny].matched = true
				
				return nx, ny
			end
		end
		return false, false
	end
	
	local function Hunt(self)
		--grid.each_with_index do |row, y|
		for x=1,self.cwidth  do
		
			--row.each_with_index do |cell, x|
			for y=1,self.cheight do
			
				local cell = self.cgrid[x][y]
				
				--next unless cell == 0
				if not cell.matched then
				
					local neighbors = {}
					local ncount = 0
					if y < self.cheight and self.cgrid[x][y+1].matched then
						ncount = ncount + 1; neighbors[ncount] = N;
					end
					if y > 1 and self.cgrid[x][y-1].matched then
						ncount = ncount + 1; neighbors[ncount] = S;
					end
					if x < self.cwidth and self.cgrid[x+1][y].matched then
						ncount = ncount + 1; neighbors[ncount] = E;
					end
					if x > 1 and self.cgrid[x-1][y].matched then
						ncount = ncount + 1; neighbors[ncount] = W; 
					end
					
					
					if ncount > 0 then
						local direction = neighbors[math.random(1,ncount)]
						local nx, ny = x + DX[direction], y + DY[direction]
						
						self.cgrid[x][y][ direction ] = true
						self.cgrid[nx][ny][ OPPOSITE[direction] ] = true
						
						self.cgrid[x][y].matched = true
						self.cgrid[nx][ny].matched = true
						
						echo(direction, x, y, nx, ny )
						
						return x, y
					end
				end
			end
		end
		return false, false
	end
	
	local function HuntAndKill(self)
		local x = math.random(1,self.cwidth)
        local y = math.random(1,self.cheight)
		
		while x do
			x, y = Walk(self, x, y)
			if x then
				x, y = Hunt(self)
			else
				echo 'no x can\'t hunt'
			end
		end
	end
	--]]
	
	
    local function CarveMaze(self)
		HuntAndKill(self)
    end
    
    
    
    MazeMasterHuntKill = function(...)
        local self = MazeMasterCarver(...)
        if not self then return false end
		
        --todo, make this nicer
		self.CarveMaze = CarveMaze --override
        
        return self
    end--constr
end--do MazeMasterHuntKill



---------- CLASS MazeMasterRecDiv

MazeMasterRecDiv = function() end;
do
	local N, E = 'n', 'e'

	local function choose_orientation(w,h)
		if w < h then return 'horizontal' end
		if h < w then return 'vertical' end
		if math.random() > 0.5 then return 'horizontal' end
		return 'vertical'
		
	end
	
	local function SetMinCorridor(self, val)
		self.minCorridor = val
	end
	local function SetDepth(self, val)
		self.depth = val
	end
	
	local function divide(self, x, y, width, height, orientation, depth)
		local minCorridor = self.minCorridor+0
	
		if width < 2+minCorridor  or height < 2+minCorridor  then return end
		
		if depth > self.depth then return end
		depth = depth + 1
		
		--horizontal = orientation == HORIZONTAL
		local horizontal = orientation == 'horizontal'
		
		-- where will the wall be drawn from?
		
		local wx = x + ( horizontal and 0 or math.random( 0+minCorridor/2 ,width-2-minCorridor/2 ) )
		local wy = y + ( horizontal and math.random( 0+minCorridor/2,height-2-minCorridor/2 ) or 0 )
		
		-- where will the passage through the wall exist?
		local px = wx + ( horizontal and math.random( 0,width-1 ) or 0 )
		local py = wy + ( horizontal and 0 or math.random( 0,height-1 ) )
		
		-- what direction will the wall be drawn?
		local dx = horizontal and 1 or 0
		local dy = horizontal and 0 or 1
		
		-- how long will the wall be?
		local length = horizontal and width or height
		
		-- what direction is perpendicular to the wall?
		local dir = horizontal and N or E
		
		for i=1,length do
			if wx ~= px or wy ~= py then
				self.cgrid[wx][wy][ dir ] = true
			else
				if dir == N then
					self.cgrid[wx][wy].door_n = true
				else
					self.cgrid[wx][wy].door_e = true
				end
			end
			wx = wx + dx
			wy = wy + dy
		end
		
		local nx, ny = x, y
		local w, h
		if horizontal then
			w,h = width, wy-y+1
		else
			w,h = wx-x+1, height
		end
		
		divide(self, nx, ny, w, h, choose_orientation(w, h), depth)
		
		if horizontal then
			nx, ny = x, wy+1
		else
			nx, ny = wx+1, y
		end
		
		if horizontal then
			w,h = width, y+height-wy-1
		else
			w,h = x+width-wx-1, height
		end
		
		divide(self, nx, ny, w, h, choose_orientation(w, h), depth)
	end
	
    local function DrawMaze(self)
		divide(self, 1,1, self.cwidth, self.cheight, choose_orientation(self.cwidth, self.cheight), 1)
    end
    
    
    
    MazeMasterRecDiv = function(...)
        local self = MazeMasterWallAdder(...)
        if not self then return false end
		
        --todo, make this nicer
		self.DrawMaze = DrawMaze --override
		self.SetMinCorridor = SetMinCorridor
		self.SetDepth = SetDepth
		
		self.depth = 999
		self.minCorridor = 0
        
        return self
    end--constr
end--do MazeMasterRecDiv






return {}