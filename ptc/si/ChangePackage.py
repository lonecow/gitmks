import subprocess

class ChangePackageException(Exception):
   def __init__(self, msg, value):
      self.value = value
      self._msg = msg
   def __str__(self):
      return self._msg

def PrintCommand(command):
    string=''
    for item in command:
        if string != '':
            string += ' '
        string += item
    print(string)

class ChangePackage:
   @staticmethod
   def Create(hostname, summary, description, issueId='', user=None, password=None):
      host = hostname.split(':')[0]
      port = hostname.split(':')[1]
      command = [   'si',
                     'createcp',
                     '--issueId=\'%s\'' % issueId,
                     '--description="%s"' % description,
                     '--summary="%s"' % summary,
                     '--hostname=%s' % host,
                     '--port=%s' % port]

      if user != None:
         command.append('--user=%s' % user)

      if password != None:
         command.append('--password=%s' % password)

      #PrintCommand(command)

      proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
      proc.wait()

      if proc.returncode != 0:
         raise ChangePackageException('command returned error code %d with message [%s]' % (proc.returncode, proc.stderr.read()), 1)
      else:
         output = proc.stderr.read()
         string = output.decode(encoding='UTF-8').split(' ')

         return ChangePackage(string[4].strip())


   def __init__(self, CpId):
      self._changePackageId = CpId

   def GetChangePackageId(self):
      return self._changePackageId

   def Close(self, hostname, port, user=None, password=None):
      command = [   'si',
                    'closecp',
                    '--hostname=%s' % hostname,
                    '--port=%s' % port,
                    self._changePackageId]

      if user != None:
         command.append('--user=%s' % user)

      if password != None:
         command.append('--password=%s' % password)

      proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
      proc.wait()

      if proc.returncode != 0:
         raise ChangePackageException('command returned error code %d with message [%s]' % (proc.returncode, proc.stderr.read()), 1)
      else:
         pass

