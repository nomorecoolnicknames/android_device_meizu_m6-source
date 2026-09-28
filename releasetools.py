# Copyright (C) 2015 The CyanogenMod Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Emit commands needed for M3(s) devices during OTA installation
(installing the radio images)."""

import common
import re

def FullOTA_Assertions(info):
  print("FullOTA_Assertions not implemented")

def IncrementalOTA_Assertions(info):
  print("IncrementalOTA_Assertions not implemented")



def _ForgeByNameDir(info):
  preferred = "/dev/block/platform/mtk-msdc.0/11230000.msdc0/by-name"
  try:
    info_dict = getattr(info, "info_dict", None) or common.OPTIONS.info_dict
    fstab = info_dict.get("fstab") if info_dict else None
    if fstab:
      for mount_point in ("/boot", "/recovery", "/system", "/vendor"):
        part = fstab.get(mount_point)
        device = getattr(part, "device", None)
        if device and "/11230000.msdc0/by-name/" in device:
          return device.split("/by-name/", 1)[0] + "/by-name"
  except Exception:
    pass
  return preferred

def _ForceForgeByNamePaths(info):
  old = "/dev/block/platform/mtk-msdc.0/11240000.msdc1/by-name"
  new = "/dev/block/platform/mtk-msdc.0/11230000.msdc0/by-name"
  try:
    info.script.script = [line.replace(old, new) for line in info.script.script]
  except Exception:
    pass

def InstallImage(img_name, img_file, partition, info):
  common.ZipWriteStr(info.output_zip, img_name, img_file)
  by_name = _ForgeByNameDir(info)
  info.script.AppendExtra(('package_extract_file("' + img_name + '", "' + by_name + '/' + partition + '");'))

image_partitions = {
   'md1dsp.img'     : 'md1dsp',
   'md3rom.img'     : 'md3img',
   'md1rom.img'     : 'md1img',
   'md1arm7.img'    : 'md1arm7'
}

def FullOTA_InstallEnd(info):
  _ForceForgeByNamePaths(info)
  info.script.Print("Writing radio image...")
  for k, v in list(image_partitions.items()):
    try:
      img_file = info.input_zip.read("RADIO/" + k)
      info.script.Print("update image " + k + "...")
      InstallImage(k, img_file, v, info)
    except KeyError:
      print(("warning: no " + k + " image in input target_files; not flashing " + k))


def IncrementalOTA_InstallEnd(info):
  _ForceForgeByNamePaths(info)
  for k, v in list(image_partitions.items()):
    try:
      source_file = info.source_zip.read("RADIO/" + k)
      target_file = info.target_zip.read("RADIO/" + k)
      if source_file != target_file:
        InstallImage(k, target_file, v, info)
      else:
        print((k + " image unchanged; skipping"))
    except KeyError:
      print(("warning: " + k + " image missing from target; not flashing " + k))
