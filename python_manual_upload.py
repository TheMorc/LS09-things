#mod upload sranda
#Morc, výmysel vznikol 11.4.2022 19:08
#toto je tak otrasný bordelkód, tak ale čo už, hlavne že to robí to čo má

import re
import sys
import os
import zipfile
import rarfile
import requests
from internetarchive import get_item
from random import randint

mod_path = sys.argv[1]
mod_name = sys.argv[2]
mod_author = sys.argv[3]
mod_tag = sys.argv[4]
mod_image = sys.argv[5]
mod_path_file_name = os.path.basename(mod_path)
mod_image_save_file = ""

# https://stackoverflow.com/a/56951135
def download(url: str, dest_folder: str):

    filename = url.split('/')[-1].replace(" ", "_")  # be careful with file names
    file_path = os.path.join(dest_folder, filename)

    r = requests.get(url, stream=True)
    if r.ok:
        print("saving to", os.path.abspath(file_path))
        with open(file_path, 'wb') as f:
            for chunk in r.iter_content(chunk_size=1024 * 8):
                if chunk:
                    f.write(chunk)
                    f.flush()
                    os.fsync(f.fileno())
    else:  # HTTP status code 4XX/5XX
        print("Download failed: status code {}\n{}".format(r.status_code, r.text))
        
        

print("Mod/map path: " + mod_path + "\tMod/map file name: " + mod_path_file_name)
print("Mod/map author: " + mod_author + "\tMod/map tag: " + mod_tag)
if mod_image == "":
	print("No mod/map image url.")
else:
	print("Mod/map image url: " + mod_image)
if mod_path_file_name.endswith(".zip"):
	archive = zipfile.ZipFile(mod_path, "r")
elif mod_path_file_name.endswith(".rar"):
	archive = rarfile.RarFile(mod_path, "r")
else:
	print("File is not a zip/rar archive file!")
print("Mod/map date: {0[0]}-{0[1]}-{0[2]}".format(archive.infolist()[0].date_time))
if mod_image.startswith("http"):
	download(mod_image, dest_folder=mod_path.replace(mod_path_file_name,""))
	mod_image_save_file = os.path.abspath(os.path.join(mod_path.replace(mod_path_file_name,""), mod_image.split('/')[-1].replace(" ", "_")))
else:
	mod_image_save_file = mod_image
print("Mod/map image file: " + mod_image_save_file)
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
      'date': "{0[0]}-{0[1]}-{0[2]}".format(archive.infolist()[0].date_time),
      'description': " ",
      'subject': ['komeo', 'LS Mods Community', mod_tag],
      'creator': mod_author}

if mod_image == "":
	mod_upload.upload(mod_path, metadata=md, verbose=True)
else:
	mod_upload.upload(files=[mod_path, mod_image_save_file], metadata=md, verbose=True)
os.rename(mod_path, mod_path.replace(mod_path_file_name,"") + "LSmods_done/" + mod_path_file_name)
uploaded_mod_list = open("uploaded_mods.txt","a")
uploaded_mod_list.write('ls2009_'+upload_mod_name+"\n")
uploaded_mod_list.close()
if mod_image != "":
	os.remove(mod_image_save_file)
