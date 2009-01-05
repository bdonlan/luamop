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

function Animal.BUILD(self)
	self.species = self:getSpecies()
	self.name = false
end

Animal.fields.name = "unnamed"

function Animal.bark(self)
	print("The " .. self.name .. " barks!")
end

dog = Animal:newinstance()
print(dog.name)
dog.name = "dog"
print(dog.name)
dog:bark()

bear = Animal:newinstance()
print(bear.name)
bear.name = "bear"
print(bear.name)
bear:bark()
print(dog.name)

Animal:bark() -- should fail as bark is an instance method
