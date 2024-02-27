extends InventoryData
class_name InventoryDataEquip

func drop_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	if !(grabbed_slot_data.item_data is ItemDataEquip):
		return grabbed_slot_data
	
	match [index, grabbed_slot_data.item_data.type]:
		[0, "Head"]:
			return super.drop_slot_data(grabbed_slot_data, index)
		[1, "Chest"]:
			return super.drop_slot_data(grabbed_slot_data, index)
		[2, "Legs"]:
			return super.drop_slot_data(grabbed_slot_data, index)
		[3, "Ring"]:
			return super.drop_slot_data(grabbed_slot_data, index)
		[4, "Necklace"]:
			return super.drop_slot_data(grabbed_slot_data, index)
		[5, "Belt"]:
			return super.drop_slot_data(grabbed_slot_data, index)
	
	return grabbed_slot_data

func drop_single_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	if !(grabbed_slot_data.item_data is ItemDataEquip):
		return grabbed_slot_data
		
	return super.drop_single_slot_data(grabbed_slot_data, index)
