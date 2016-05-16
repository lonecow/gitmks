import time
import threading

class ImException(Exception):
   def __init__(self, msg, value):
      self.value = value
      self._msg = msg
   def __str__(self):
      return self._msg

def __ThreadWorker(Process, timeout):
   """
   :type Process: subprocess
   """
   StartTime = time.clock()
   while time.clock() - StartTime < timeout:
      time.sleep(.01)
      if Process.poll() != None:
         break

   if Process.poll() == None:
      Process.kill()
   
def ProcessCommunicate(Process, timeout):
   thread = threading.Thread(target=__ThreadWorker, args=(Process, timeout))
   outs, errs = Process.communicate()
   return (outs, errs)

