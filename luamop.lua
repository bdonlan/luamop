function __blessClass(class)
	local meta = getmetatable(class)
	meta.__newindex = class.methods
end

function __createInstance(class)
	local object = {}
	__blessInstance(class, object)
	return object
end

function __inheritSearch(self, name)
	local class = getClass(self)
	local impl = class:search(name)
	self[name] = impl
	return impl
end

function __blessInstance(class, object)
	--print("BI: class is ", class)
	local meta = { __index = __inheritSearch, __newindex = rawset, class = class }
	setmetatable(object, meta)
end

function getClass(object)
	local meta = getmetatable(object)
	return meta.class
end

ObjectClass = {
	name = "ObjectClass",
	methods = {
	}
}
ObjectClass.super = ObjectClass

__classSearch = function(class, name)
	local impl = class.methods[name]
	if impl then
		return impl
	end
	if class.super == class then
		return nil
	else
		return class.super:search(name)
	end
end

ClassClass = {
	name = "ClassClass",
	methods = {
		search = __classSearch
	},
	search = __classSearch,
	super = ObjectClass
}

__blessInstance(ClassClass, ObjectClass)
__blessInstance(ClassClass, ClassClass)
__blessClass(ObjectClass)
__blessClass(ClassClass)

function ObjectClass.BUILDALL(self, ...)
	local recurse = nil
	recurse = function(class, ...)
		if not(class.super == class) then
			recurse(class.super, ...)
		end
		if class.methods.BUILD then
			class.methods.BUILD(...)
		end
	end
	recurse(getClass(self), self, ...)
end

function ClassClass.newinstance(class, ...)
	--print("Instantiating ", class)
	local inst = {}

	__blessInstance(class, inst)
	inst:BUILDALL(...)
	return inst
end

function ClassClass.BUILD(self, args)
	if not(args) then
		args = {}
	end

	local super = args.super
	if not(super) then
		super = ObjectClass
	end
	if args.name then
		self.name = name
	else
		self.name = "Unnamed"
	end
	self.super = super
	self.methods = {}
	__blessClass(self)
end

function ClassClass.around(self, name, wrapper)
	local base = self:search(name)
	local function impl(...)
		return wrapper(base, ...)
	end
	self.methods[name] = impl
end

function ClassClass.before(self, name, wrapper)
	self:around(name, function(base, ...)
		wrapper(...)
		return base(...)
	end)
end

function ClassClass.after(self, name, wrapper)
	self:around(name, function(base, ...)
		local ret = base(...)
		wrapper(ret, ...)
		return ret
	end)
end
--print("Creating a new class using ClassClass=", ClassClass)
Animal = ClassClass:newinstance()

function Animal.getSpecies(self)
	return "animal"
end

function Animal.BUILD(self, args)
	if args and args.name then
		self.name = args.name
	else
		self.name = false
	end
end

function Animal.barkstr(self, args)
	local str = "The " .. self:getSpecies()
	if self.name then
		str = str .. " named " .. self.name
	end
	str = str .. " barks"
	if args and args.target then
		str = str .. " at " .. args.target
	end
	str = str .. "!"
	return str
end

function Animal.bark(self, ...)
	print(self:barkstr(...))
end

rawset(Animal, "newspecies", function(self, speciesname)
	local class = getClass(self):newinstance{super = self}
	function class.getSpecies(self)
		return speciesname
	end
	return class
end)

Wolf = Animal:newspecies("wolf")
Wolf:around("barkstr", function(base, self, ...)
	local retval = base(self, ...)
	retval = string.gsub(retval, "barks", "howls")
	return retval
end)
lupin = Wolf:newinstance{name = "Lupin"}
lupin:bark{target = "the moon"}

Dog = Animal:newspecies("dog")
Dog:after("bark", function(self, ...)
	print("It then slobbers on your leg.")
end)
fido = Dog:newinstance{name = "Fido"}
fido:bark()
Dog:newinstance():bark()

Bear = Animal:newspecies("bear")
yogi = Bear:newinstance{name = "Yogi"}
yogi:bark()
fido:bark()

Grue = Animal:newspecies("grue")
Grue:before("bark", function(self, ...)
	print("It is dark.");
end)
grue = Grue:newinstance()
grue:bark()

-- Animal:bark() -- should fail as bark is an instance method
