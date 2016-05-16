from __future__ import print_function

import subprocess
import os

class ViewProjectException(Exception):
   def __init__(self, msg, value):
      self.value = value
      self._msg = msg
   def __str__(self):
      return self._msg

class ViewProject:
   def __init__(self, Project, hostname=None, user=None, password=None, verbose=False):
      self._hostname=hostname
      self._user=user
      self._password=password
      self._path = Project
      self._data = []
      command = [   'si',
                     'viewproject',
                     '-P', Project,
                     '--fields', 'type,name',
                     '--norecurse']

      if self._hostname != None:
         command.append('--hostname=%s' % hostname)

      if self._user != None:
         command.append('--user=%s' % user)

      if self._password != None:
         command.append('--password=%s' % password)

      if verbose:
         """Print out the command string"""
         cmd_string = ''
         for item in command:
            if cmd_string != '':
               cmd_string = cmd_string + ' '
            cmd_string = cmd_string + item 
         print(cmd_string)

      proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

      try:
          outs, errs = proc.communicate(timeout=360)
      except TimeoutExpired:
          proc.kill()
          outs, errs = proc.communicate()

      if proc.returncode != 0:
         raise ViewProjectException('command returned error code %d with message [%s]' % (proc.returncode, proc.stderr.read()), 1)
      else:
         string = outs.decode(encoding='UTF-8').split('\n')
         new_dict = None

         for line in string:
            if line != '':
               sub_type = line.split(' ')[0]
               sub_name = line[len(sub_type) + 1:]
               if '(' in sub_name:
                  sub_name = sub_name.split('(')[0]
               path = '%s/%s' % (os.path.dirname(self._path), sub_name)
               new_dict = {   'Type':sub_type,
                              'Name':sub_name,
                              'Path': path,
                              'BasePath': os.path.dirname(path)}
               if new_dict != None:
                  self._data.append(new_dict)

   def Children(self):
      return self._data

   def GetPath(self):
      return self._path

