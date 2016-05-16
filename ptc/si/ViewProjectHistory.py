import subprocess
from .Utils import SiException 
from sys import stdout, stderr

class ViewProjectHistory:
   def __init__(self, Project, hostname=None, user=None, password=None, verbose=False):
      self._hostname=hostname
      self._user=user
      self._password=password
      self._data = []
      self._cmd_output = ''
      command = [   'si',
                     'viewprojecthistory',
                     '-P', Project,
                     '--fields', 'revision,labels']

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

      for line in self._cmd_output[1:]:
         if line != '':
            split_line = line.split('\t')
            if len(split_line) > 1:
               labels = split_line[1].split(',')

               run_again = True
               while(run_again):
                  run_again = False
                  for idx in range(len(labels)):
                     if labels[idx] == '':
                        if idx > 0:
                           labels[idx - 1] = labels[idx - 1] + ','
                        del labels[idx]
                        run_again = True
                        break
            else:
               labels = []

            new_data = {'Revision':split_line[0],
                        'Labels':labels}
            self._data.append(new_data)

   def Labels(self):
      ret_val = []
      for item in self._data:
         ret_val.extend(item['Labels'])
      return ret_val

