import subprocess
from .Utils import SiException 
from sys import stdout, stderr

class ProjectInfo:
   def __init__(self, Project, hostname=None, user=None, password=None, verbose=False):
      self._hostname=hostname
      self._user=user
      self._password=password
      self._data = {}
      self._cmd_output = ''
      command = [   'si',
                     'projectinfo',
                     '-P',
                     Project]

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
         raise SiException('command returned error code %d with message [%s]' % (proc.returncode, errs.decode(encoding='UTF-8')), 1)
      else:
         self._cmd_output = outs.decode(encoding='UTF-8').split('\n')

      for line in self._cmd_output:
         if line.startswith('Configuration Path: '):
            self._data['ConfigurationPath'] = line[len('Configuration Path: '):].split(', ')[0]
         if line.startswith('Repository Location: '):
            self._data['FullPath'] = line[len('Repository Location: '):]

      if 'ConfigurationPath' in self._data:
         self._data['ProjectPath'] = self._data['ConfigurationPath'].split('#')[1].split('p=')[1]
      
   
   def GetConfigurationPath(self):
      if 'ConfigurationPath' in self._data:
         return self._data['ConfigurationPath']
      else:
         return ''

   def GetProjectPath(self):
      if 'ProjectPath' in self._data:
         return self._data['ProjectPath']
      else:
         return ''

   @property
   def FullPath(self):
      if 'FullPath' in self._data:
         return  self._data['FullPath']
      return ''

