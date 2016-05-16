
class SiException(Exception):
   def __init__(self, msg, value):
      self.value = value
      self._msg = msg
   def __str__(self):
      return self._msg

