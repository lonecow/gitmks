
import subprocess
from .Utils import ImException, ProcessCommunicate
from sys import stdout, stderr

class BaseIssue:
   def __init__(self, ItemId, hostname=None, user=None, password=None, verbose=False):
      self._hostname=hostname
      self._user=user
      self._password=password
      self._data = {}
      self._verbose = verbose

      cmd_output = ''
      command = [   'im',
                     'viewissue',
                     ItemId]

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

      outs, errs = ProcessCommunicate(proc, timeout=360)

      if proc.returncode != 0:
         raise ImException('command returned error code %d with message [%s]' % (proc.returncode, errs.decode(encoding='UTF-8')), 1)
      else:
         cmd_output = outs.decode(encoding='UTF-8').split('\n')

      """ Adding type to the list of variables to parse """
      self._single_var_info.append(('Type', 'Type: '))

      for line in cmd_output:
         for (store_name, line_name) in self._single_var_info:
            if line.startswith(line_name):
               self._data[store_name] = line[len(line_name):]

         for (store_name, line_name) in self._multi_ele_var_info:
            if line.startswith(line_name):
               if ',' in line:
                  self._data[store_name] = line[len(line_name):].split(', ')
   
   def GetType(self):
      return self._data['Type']

   def GetName(self):
      return self._data['Name']

   def NumIssuesToBeAnalyzed(self):
      return int(self._data['Issues_To_Be_Analyzed_Count'])

   def NumIssuesAnalyzed(self):
      return int(self._data['Issues_Analyzed_Count'])
   
   def NumIssuesToBeImplemented(self):
      return int(self._data['Issues_To_Be_Implemented_Count'])

   def NumIssuesImplemented(self):
      return int(self._data['Issues_Implemented_Count'])

   def NumIssuesSubmitted(self):
      return int(self._data['Issues_Submitted_Count'])


class ViewReleaseCandidate(BaseIssue):
   _single_var_info = [
      ('Name',                            'Release Candidate: '                                             ),
      ('Issues_To_Be_Analyzed_Count',     'Restraints_Release_Candidate_Issues_To_Be_Analyzed_Count: '      ),
      ('Issues_Analyzed_Count',           'Restraints_Release_Candidate_Issues_Analyzed_Count: '            ),
      ('Issues_To_Be_Implemented_Count',  'Restraints_Release_Candidate_Issues_To_Be_Implemented_Count: '   ),
      ('Issues_Implemented_Count',        'Restraints_Release_Candidate_Issues_Implemented_Count: '         ),
      ('Issues_Submitted_Count',          'Restraints_Release_Candidate_Issues_Submitted_Count: '           )]

   _multi_ele_var_info = []

   def __init__(self, ItemId, hostname=None, user=None, password=None, verbose=False):
      super(ViewReleaseCandidate, self).__init__(ItemId, hostname, user, password, verbose)

      if self.GetType() != u'ALE Release Candidate':
         raise ImException('Issue [%s] is not an ALE Release Candidate [%s]' % (ItemId, self.GetType()), 1)

class ViewReleaseContainer(BaseIssue):
   _releaseCandidates = None

   _single_var_info = [
      ('Total_Issues_Open',               'Restraints_Release_Container_Total_Issues_Open: '          ),
      ('Name',                            'Release Container: '                                       ),
      ('Issues_Submitted_Count',          'Restraints_Release_Container_Submitted_Count: '            ),
      ('Issues_To_Be_Analyzed_Count',     'Restraints_Release_Container_To_Be_Analyzed_Count: '       ),
      ('Issues_Analyzed_Count',           'Restraints_Release_Container_Analyzed_Count: '             ),
      ('Issues_To_Be_Implemented_Count',  'Restraints_Release_Container_To_Be_Implemented_Count: '    ),
      ('Issues_Implemented_Count',        'Restraints_Release_Container_Implemented_Count: '          ),
      ('Issues_To_Be_Integrated_Count',   'Restraints_Release_Container_To_Be_Integrated_Count: '     ),
      ('Issues_Integrated',               'Restraints_Release_Container_Integrated_Count: '           ),
      ('Issues_To_Be_Verified_Count',     'Restraints_Release_Container_To_Be_Verified_Count: '       ),
      ('Issues_Verified_Count',           'Restraints_Release_Container_Verified_Count: '             ),
      ('Issues_Closed_Count',             'Restraints_Release_Container_Closed_Count: '               ),
      ('Issues_MemberMove',               'Restraints_Release_Container_MemberMove_Count: '           )]

   _multi_ele_var_info = [
      ('ReleaseCandidates',   'Create Release Candidate: ')]

   def __init__(self, ItemId, hostname=None, user=None, password=None, verbose=False):
      super(ViewReleaseContainer, self).__init__(ItemId, hostname, user, password, verbose)

   def GetNumberOpenIssues(self):
      return int(self._data['Total_Issues_Open'])

   def NumIssuesToBeVerified(self):
      return int(self._data['Issues_To_Be_Verified_Count'])

   def NumIssuesVerified(self):
      return int(self._data['Issues_Verified_Count'])

   def Issues_Closed_Count(self):
      return int(self._data['Issues_Closed_Count'])

   def TotalIssues(self):
      return int(self._data['Total_Issues_Count'])
   
   def GetReleaseCandidates(self):
      if self._releaseCandidates == None:
         if 'ReleaseCandidates' in self._data:
            self._releaseCandidates = [ViewReleaseCandidate(x, verbose=self._verbose) for x in self._data['ReleaseCandidates']]
         else:
           self._releaseCandidates = []
      return self._releaseCandidates

class ViewProject(BaseIssue):
   _single_var_info = [
      ('Name',                               'Project: '                                              ),
      ('Issues_To_Be_Analyzed_Count',        'Restraints_Project_Issues_To_Be_Analyzed_Count: '       ),
      ('Issues_Analyzed_Count',              'Restraints_Project_Issues_Analyzed_Count: '             ),
      ('Issues_To_Be_Implemented_Count',     'Restraints_Project_Issues_To_Be_Implemented_Count: '    ),
      ('Issues_Implemented_Count',           'Restraints_Project_Issues_Implemented_Count: '          ),
      ('Issues_To_Be_Integrated_Count',      'Restraints_Project_Issues_To_Be_Integrated_Count: '     ),
      ('Issues_Integrated_Count',            'Restraints_Project_Issues_Integrated_Count: '           ),
      ('Issues_To_Be_Verified_Count',        'Restraints_Project_Issues_To_Be_Verified_Count: '       ),
      ('Issues_Verified_Count',              'Restraints_Project_Issues_Verified_Count: '             ),
      ('Issues_Submitted_Count',             'Restraints_Project_Issues_Submitted_Count: '            ),
      ('Issues_Postponed_Count',             'Restraints_Project_Issues_Postponed_Count: '            ),
      ('Total_Issues_Count',                 'Restraints_Project_Total_Issues_Count: '                ),
      ('Issues_Closed_Count',                'Restraints_Project_Issues_Closed_Count: '               )]

   _multi_ele_var_info = [
      ('Release_Containers_List',   'Restraints_Project_Release_Containers_List: ')]

   def __init__(self, ItemId, hostname=None, user=None, password=None, verbose=False):
      super(ViewProject, self).__init__(ItemId, hostname, user, password, verbose)

   def GetReleaseContainers(self):
      return_value = []
      for item in self._data['Release_Containers_List']:
         return_value.append(ViewReleaseContainer(item, verbose=self._verbose))
      return return_value

   def NumIssuesToBeIntegrated(self):
      return int(self._data['Issues_To_Be_Integrated_Count'])

   def NumIssuesToBeVerified(self):
      return int(self._data['Issues_To_Be_Verified_Count'])

   def NumIssuesVerified(self):
      return int(self._data['Issues_Verified_Count'])

   def NumIssuesPostponed(self):
      return int(self._data['Issues_Postponed_Count'])

   def Issues_Closed_Count(self):
      return int(self._data['Issues_Closed_Count'])

   def TotalIssues(self):
      return int(self._data['Total_Issues_Count'])

