
----------------------------------------------------------------------------------------------
-- getUI( name )
function getUI( name )
	local uiRoot = queryObject("UIRoot")
	if uiRoot == nil then
		return nil
	end
	return uiRoot:UI_GET_CHILD(name)
end

----------------------------------------------------------------------------------------------
-- populateTypeTree( )
-- populates the entity editor type ui on the left in a tree structure modeled after XML Notepad
-- so we can visualize the entity type tree

function populateTypeTree( )
	
	-- get the component which we will populate the tree with
	local component = getUI("TypeTree")
	if component == nil then
		return
	end
	
	-- destroy all the current children if there are any
	component:UI_DESTROY_CHILDREN()
	
	-- call the recursive method which populates the tree starting with an entity type
	addTypeUIToTree(component, "entity")
end
----------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------
-- addTypeUIToTree( layout, entityType )
-- Helper for populateTypeTree(). adds a UI element representing the type to a given layout in 
-- the type tree

function addTypeUIToTree( layout, entityType )
	
	local bfgMgr = queryObject("BFGManager")
	if layout == nil or entityType == nil or bfgMgr == nil then
		return
	end

	-- load the new ui component	
	local component = layout:UI_LOAD_CHILD("ui/layout/entityeditor/typeentry.xml")
	if component == nil then
		return
	end
	
	--set the name of the component to the name of the type
	component:UI_SET_NAME(entityType)
	
	-- acquire the expander button and the button for the type from the layout we just loaded
	local expander = component:UI_GET_CHILD("expander")
	local typebutton = component:UI_GET_CHILD("typeentry")
	
	--set the text of the type button to the name of the type
	if typebutton ~= nil then	
		typebutton:UI_SET_TEXT(entityType)
	end

	-- get the list of subtypes for this type	
	local subTypes = bfgMgr:BFG_FIND_DERIVED_TYPES_IMMEDIATE(entityType)
	local subTypesSize = table.getn(subTypes)
	if subTypes ~= nil and subTypesSize > 0 then		
		-- recursively add all the subtypes to this layout
		for i = 1, subTypesSize do
			addTypeUIToTree(component, subTypes[i].value)
		end

		-- since we have sub-types, the expander button needs to be enabled
		if expander ~= nil then
			expander:UI_ENABLE()	
			if entityType ~= "entity" then
				--for all expanders except for entity, collapse it
				expander:UI_ACTIVATE_OFF()
			end
		end		
	end
	
end
----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
-- populateSelectedType( )
-- Populates the UI with the selected type

function populateSelectedType( )


end
----------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------
-- populateInheritance( ) 
function populateInheritance( )
	
	-- extract the name of the type from the text box which contains it
	local component = getUI("Selected Type Label")
	if component == nil then
		return
	end
		
	local entityType = component:UI_GET_TEXT()
	
	-- the type tree is a UIComponent which models the type heirarchy.
	-- we can get parent types by looking at a UIComponent's parent
	local typeTree = getUI("TypeTree")
	if typeTree == nil then
		return
	end
	
	local inheritanceLayout = getUI("Inheritance Types")
	if inheritanceLayout == nil then
		return
	end
	
	--first clear the inheritance listbox
	inheritanceLayout:UI_DESTROY_CHILDREN()
	
	-- get the component in the heirarchy
	component = typeTree:UI_GET_CHILD(entityType)
	if component == nil then
		return
	end
	
	-- populate the inheritance list box along the top
	local currentType = entityType
	local typeArray = {}
	local arrayCount = 1
	
	-- populate a type array with the heirarchy
	while currentType ~= nil do
		typeArray[arrayCount] = currentType
		arrayCount = arrayCount + 1
		if currentType == "entity" then
			currentType = nil
		else
			component = component:UI_GET_PARENT()
			currentType = component:UI_GET_NAME()
		end
		
	end
	
	-- go through the array in reverse to populate the heirarchy listbox
	-- with buttons corresponding to each type
	local button = nil
	for arrayCount = table.getn(typeArray), 1, -1 do
		currentType = typeArray[arrayCount]
		
		-- create the button and label it
		button = inheritanceLayout:UI_LOAD_CHILD("ui/layout/entityeditor/inheritance.xml")
		button:UI_SET_TEXT(currentType)
		
		-- size it
		local rect = button:UI_GET_STRING_SIZE()
		button:UI_SET_SIZE({x=rect.w + 12, y=rect.h})
		
		
		
	end
	
	
	if button ~= nil then
		--acivate the first button
		button:UI_ACTIVATE_ON()
	end
end
----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
-- reloadBinder( )
-- Reloads the selected type

function reloadBinder( )
	-- extract the name of the type from the text box which contains it
	local component = getUI("Selected Type Label")
	if component == nil then
		return
	end

	local worldMgr = queryObject("ZTWorldMgr")
	if worldMgr == nil then
		return
	end
	
	local bfgMgr = queryObject("BFGManager")
	if bfgMgr == nil then
		return
	end
		
	-- just in case we're in placement mode,take the thing off the cursor so we don't crash
	local mode = queryObject("ZTMode");
	if mode ~= nil then
		mode:sendMessage("ZT_SETPLACEMENTOBJECT")
		mode:sendMessage("ZT_SETMODE", "mode_selection")
	end
		
	-- get the entity type from the field
	local entityType = component:UI_GET_TEXT()
	
	--first we have to remove all entitys that we will reload from the map, otherwise there will be a crash
	local entitylist = bfgMgr:BFG_GET_ENTITIES(entityType)
	if (entitylist ~= nil and type(entitylist) == "table") then
		local count = table.getn(entitylist)
		for i = 1, count do
			local entity = resolveTable(entitylist[i].value)
			if entity ~= nil then
				bfgMgr:BFG_REMOVE_ENTITY(entity)
			end
		end
	end
	
	--tell the world manager to reload the binder
	worldMgr:ZT_RELOAD_BINDER(entityType)
	worldMgr:ZT_CLEANUP_TRASHED_BINDERS()
end
----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
-- reloadBinderAndReplace( )
-- Reloads the selected type and replaces all instances of the old version with new

function reloadBinderAndReplace( )

	-- extract the name of the type from the text box which contains it
	local component = getUI("Selected Type Label")
	if component == nil then
		return
	end

	local worldMgr = queryObject("ZTWorldMgr")
	if worldMgr == nil then
		return
	end
	
	local bfgMgr = queryObject("BFGManager")
	if bfgMgr == nil then
		return
	end

	-- just in case we're in placement mode,take the thing off the cursor so we don't crash
	local mode = queryObject("ZTMode");
	if mode ~= nil then
		mode:sendMessage("ZT_SETPLACEMENTOBJECT")
		mode:sendMessage("ZT_SETMODE", "mode_selection")
	end
		
	-- get the entity type from the field
	local entityType = component:UI_GET_TEXT()

	--first get a list of all the entities of the given type
	local entitylist = bfgMgr:BFG_GET_ENTITIES(entityType)

	--tell the world manager to reload the binder
	worldMgr:ZT_RELOAD_BINDER(entityType)

		
	if (entitylist ~= nil and type(entitylist) == "table") then
		local count = table.getn(entitylist)
		for i = 1, count do
			local entity = resolveTable(entitylist[i].value)
			if entity ~= nil then
				local binderType = entity:BFG_GET_BINDER_TYPE()
				entity:BFG_ENTITY_MORPH_TO_NEW_ENTITY(binderType)
			end
		end
	end

	worldMgr:ZT_CLEANUP_TRASHED_BINDERS()
end

----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
-- sendMessageToChildrenByName( layout, childName, messageType )
-- Sends a message to all children (and decendants) of a layout with a given name

function sendMessageToChildrenByName( layout, childName, messageType )

	if layout == nil then
		return
	end
	
	-- get the list of children from the layout
	local childrenList = layout:UI_GET_CHILDREN()
	if childrenList == nil or type(childrenList) ~= "table" then
		return
	end
	
	-- keep a table of the named children so we can send the message at the end of the algorithm
	local namedChildren = { }
	
	-- iterate through all the children and send a message to the ones with the proper name
	local count = table.getn(childrenList)
	for i = 1, count do
		-- extract the component from the table
		local component = resolveTable(childrenList[i].value)
		if component ~= nil then
			-- get the name of the child and compare it to our child name
			local name = component:UI_GET_NAME()
			if name == childName then
				-- it's a match, so send it the message
				--component:sendMessage(messageType)
				namedChildren[table.getn(namedChildren) + 1] = component
			else
				-- do the deep search of this componet
				sendMessageToChildrenByName(component, childName, messageType)
			end
		end
	end
	
	-- iterate through the named children and send the message
	count = table.getn(namedChildren)
	for i = 1, count do
		namedChildren[i]:sendMessage(messageType)
	end
end

----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
-- expandTree( layoutName )
-- Expands a tree by pressing all the buttons called "expander" within a given layout

function expandTree( args )
	
	-- args should contain an element which is the name of the layout
	if args == nil or type(args) ~= "table" or table.getn(args) < 1 then
		return
	end
	
	-- extract the layout from the name (which is the first of args)
	local layout = getUI(args[1].value)
	if layout == nil then
		return
	end
	
	-- tell all buttons called "expander" to activate on
	sendMessageToChildrenByName( layout, "expander", "UI_ACTIVATE_ON")
	
end
----------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------
-- collapseTree( layoutName )
-- Collapse's a tree by un-pressing all the buttons called "expander" within a given layout

function collapseTree( args )

	-- args should contain an element which is the name of the layout
	if args == nil or type(args) ~= "table" or table.getn(args) < 1 then
		return
	end
	
	-- extract the layout from the name (which is the first of args)
	local layout = getUI(args[1].value)
	if layout == nil then
		return
	end
	
	-- tell all buttons called "expander" to activate off
	sendMessageToChildrenByName( layout, "expander", "UI_ACTIVATE_OFF")

end
----------------------------------------------------------------------------------------------


