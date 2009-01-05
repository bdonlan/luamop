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
	while class do
		--print("Search ", class.name, " for ", name, " on ", self)
		local impl = class.methods[name]
		if impl then
			self[name] = impl
			return impl
		end
		if class.super == class then
			class = nil
		else
			--print("Super of ", class, "(", class.name, ") is ", class.super, "(", class.super.name, ")")
			class = class.super
		end
	end
	return nil
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
	},
	fields = {}
}
ObjectClass.super = ObjectClass

ClassClass = {
	name = "ClassClass",
	methods = {
	},
	fields = {
		methods = nil,
		super = nil,
		fields = nil,
		name = "Unnamed",
	},
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
	local classp = class
	while classp do
		--print("class=", classp, " fields=", classp.fields)
		for k, v in pairs(classp.fields) do
			inst[k] = v
		end
		if classp.super == classp then
			classp = nil
		else
			classp = classp.super
		end
	end

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
	self.super = super
	self.methods = {}
	self.fields = {}
	__blessClass(self)
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

Animal.fields.name = "unnamed"

function Animal.bark(self)
	local str = "The " .. self:getSpecies()
	if self.name then
		str = str .. " named " .. self.name
	end
	str = str .. " barks!"
	print(str)
end

rawset(Animal, "newspecies", function(self, speciesname)
	local class = getClass(self):newinstance{super = self}
	function class.getSpecies(self)
		return speciesname
	end
	return class
end)


Dog = Animal:newspecies("dog")
fido = Dog:newinstance{name = "Fido"}
fido:bark()

Bear = Animal:newspecies("bear")
yogi = Bear:newinstance{name = "Yogi"}
yogi:bark()
fido:bark()

Animal:bark() -- should fail as bark is an instance method
