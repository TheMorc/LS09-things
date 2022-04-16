#mod upload sranda
#Morc, výmysel vznikol 11.4.2022 19:08
#toto je tak otrasný bordelkód, tak ale čo už, hlavne že to robí to čo má

import zipfile
import warnings
import re
import sys
import os
from bs4 import BeautifulSoup
from internetarchive import get_item
from random import randint

warnings.filterwarnings("ignore", category=UserWarning, module='bs4')
mod_path = sys.argv[1]
mod_path_file_name = os.path.basename(mod_path)
print("Mod path: " + mod_path + "\tMod file name: " + mod_path_file_name)
if mod_path_file_name.endswith(".zip"):
	archive = zipfile.ZipFile(mod_path, "r")
else:
	print("File is not a zip file!")
	sys.exit()
zip_prefix = ""
for file in archive.namelist():
	if file.endswith("modDesc.xml"):
		zip_prefix = file.replace("modDesc.xml","")
		if zip_prefix != "":
			print("Current zip prefix: " + zip_prefix)
if not zip_prefix + "modDesc.xml" in archive.namelist():
	print("There's no modDesc.xml in the zip, isn't this a \"multimod\" zip?")
	sys.exit()
modDesc = BeautifulSoup(archive.read(zip_prefix + "modDesc.xml"), "html.parser")
try:
	mod_name = modDesc.find("name").string
except:
	mod_name = str(modDesc.select("title > en")).replace("[<en>","").replace("</en>]","")
if mod_name == "[]":
	print("Mod doesn't have a name at all, taking filename as a name")
	mod_name = mod_path_file_name.replace(".zip","")
mod_author = ""
try:
	mod_author = modDesc.find("author").string
except:
	mod_author = "LS Mods Community"
if mod_author is None:
	mod_author = "LS Mods Community"
print("Name: " + mod_name + "\tAuthor: " + mod_author)
mod_store_image = ""
try:
	mod_store_image = modDesc.find("image")["active"]
except:
	print("This mod doesn't have a store image.")
mod_has_store_image = False
mod_store_image_found = False
if mod_store_image != "":
	mod_has_store_image = True
try:
	mod_version = modDesc.find("version").string
except:
	mod_version = "N/A"
print("Date: {0[0]}-{0[1]}-{0[2]}".format(archive.getinfo(zip_prefix + "modDesc.xml").date_time) + "\tOriginal store image path: " + mod_store_image)
mod_price = ""
try:
	mod_price = modDesc.find("price").string
except:
	print("This mod doesn't have a price.")
	mod_price = "N/A"
print("Price: " + mod_price + "\tVersion: " + mod_version)
#print("Description:")
mod_desc = str(modDesc.select("storeItem > en > description")).replace("[<description>","").replace("</description>]","").replace("<![CDATA[","").replace("]]>","")
#print(mod_desc)

try:
	for file in archive.namelist():
		temp_store_image = zip_prefix + mod_store_image
		if file.lower() == temp_store_image.lower():
			mod_store_image = file
			archive.extract(file, "")
			mod_store_image_found = True
			print("Found store image at " + mod_store_image)
except:
	print("Seems like something is broken in the store image thing section...")


#upload_mod_name = re.sub(r"^[a-zA-Z0-9][a-zA-Z0-9_.-]{4,100}$", "", mod_name).replace(" ", "") oné, toto voláko zle regexuje, možno to bude treba zas ale prerobiť
unicodespecial_mod_name = mod_name.encode("ascii", "ignore")
upload_mod_name = unicodespecial_mod_name.decode().replace(" ", "").replace("+","").replace(",","").replace("(","").replace(")","")
#sys.exit()
uploaded_mod_list = open("uploaded_mods.txt","r")
for mod in uploaded_mod_list:
	if str("ls2009_"+upload_mod_name).strip() == mod.strip():
		upload_mod_name = upload_mod_name + "_" + str(randint(0,1000))
		print("Duplicated mod id, randomizing mod id number")
uploaded_mod_list.close()
print("Uploading as: " + "ls2009_"+upload_mod_name)
mod_upload = get_item('ls2009_'+upload_mod_name)


md = {'title': mod_name, 
      'mediatype': 'software',
      'collection': 'open_source_software',
      'date': "{0[0]}-{0[1]}-{0[2]}".format(archive.getinfo(zip_prefix + "modDesc.xml").date_time),
      'description': mod_desc,
      'subject': ['LS2009 Mod', 'komeo', 'LS Mods Community'],
      'creator': mod_author,
      'price': mod_price}

if not mod_store_image_found:
	mod_upload.upload(mod_path, metadata=md, verbose=True)
else:
	mod_upload.upload(files=[mod_path, mod_store_image], metadata=md, verbose=True)
os.rename(mod_path, mod_path.replace(mod_path_file_name,"") + "LSmods_done/" + mod_path_file_name)
uploaded_mod_list = open("uploaded_mods.txt","a")
uploaded_mod_list.write('ls2009_'+upload_mod_name+"\n")
uploaded_mod_list.close()
if not mod_store_image_found and mod_has_store_image:
	print("Seems like a store image was specified but not included in the .zip")
if mod_store_image_found and mod_has_store_image:
	os.remove(mod_store_image)
	if "/" in mod_store_image:
		os.rmdir(mod_store_image.rsplit("/",1)[0]+"/")
