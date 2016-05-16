import subprocess

class DiagException(Exception):
   def __init__(self, msg, value):
      self.value = value
      self._msg = msg
   def __str__(self):
      return self._msg


class DiagLicenses:
   def __init__(self, hostname, user, password):
      self._hostname=hostname
      self._user=user
      self._password=password
      self._data = {}
      command = [   'im',
                     'diag',
                     '--diag=licenses',
                     '--hostname=%s' % hostname]

      if user != None:
         command.append('--user=%s' % user)

      if password != None:
         command.append('--password=%s' % password)

      proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
      proc.wait()

      if proc.returncode != 0:
         # TODO thow exception
         raise DiagException('command returned error code %d with message [%s]' % (proc.returncode, proc.stderr.read()), 1)
      else:
         output = proc.stdout.read()
         string = output.decode(encoding='UTF-8').split('\n')

         self._data['SiFloat'] = {}
         self._data['SiFloat']['Count'] = int(string[0].split(': ')[1])
         self._data['SiFloat']['Users'] = self._splitUsers(string[1])

         self._data['SiSeat'] = {}
         self._data['SiSeat']['Count'] = int(string[2].split(': ')[1])
         self._data['SiSeat']['Users'] = self._splitUsers(string[3])

         self._data['ImFloat'] = {}
         self._data['ImFloat']['Count'] = int(string[4].split(': ')[1])
         self._data['ImFloat']['Users'] = self._splitUsers(string[5])

         self._data['ImSeat'] = {}
         self._data['ImSeat']['Count'] = int(string[6].split(': ')[1])
         self._data['ImSeat']['Users'] = self._splitUsers(string[7])

   def __del__(self):
      command = [ 'integrity',
                  'disconnect',
                  '--hostname=%s' % self._hostname,
                  '--port=7001',
                  '--yes']

      if self._user != None:
         command.append('--user=%s' % self._user)

      if self._password != None:
         command.append('--password=%s' % self._password)

      proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
      proc.wait()

   def _splitUsers(self, InputString):
      users = []
      for element in InputString.split(', '):
         try:
            users.append(element.split(': ')[1])
         except:
            pass
      return users

   def GetSeatUsers(self):
      return self._data['ImSeat']['Users']

   def GetFloatUsers(self):
      return self._data['ImFloat']['Users']

