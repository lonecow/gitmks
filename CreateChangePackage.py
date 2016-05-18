from ptc.si import ChangePackage
from jira import JIRA
import argparse


parser = argparse.ArgumentParser(description='Creates A Jira/Ptc Change-package and returns the ID')


parser.add_argument('JiraHost', metavar='JiraHost', type=str, help='Jira Host full web address')
parser.add_argument('JiraUser', metavar='JiraUser', type=str, help='Jira UserName')
parser.add_argument('JiraPass', metavar='JiraPass', type=str, help='Jira Password')
parser.add_argument('Issue', metavar='Issue', type=str, help='Issue Number')


parser.add_argument('--ptc_user', dest='PtcUser', default=None, help='Ptc User name')
parser.add_argument('--ptc_pass', dest='PtcPass', default=None, help='Ptc Password')
parser.add_argument('--ptc_host', dest='PtcHostName', default='ALVA-MKS01:7001', help='Ptc Host in AAAA:5021')

parser.add_argument('--summary', dest='Summary', default='', help='Summary')
parser.add_argument('--description', dest='Description', default='', help='Description of change package')


parser.add_argument('--verbose', dest='VERBOSE', default=False, action='store_true', help='Add Verbose output')

if __name__ == "__main__":
   args=parser.parse_args()

   cp = ChangePackage.Create(args.PtcHostName, args.Summary, args.Description)
   jira = JIRA(args.JiraHost, basic_auth=(args.JiraUser, args.JiraPass))

   issue_dict = {
      'project': {'key': args.Issue.split('-')[0]},
      'summary': args.Summary,
      'description': args.Description,
      'issuetype': {'name': 'Change Package'},
      'parent': {'key': args.Issue},
      'customfield_10313' : 'integrity://%s/si/viewcp?selection=%s' % (args.PtcHostName, cp.GetChangePackageId())
   }
   new_issue = jira.create_issue(fields=issue_dict)

   print(cp.GetChangePackageId())
   exit(0)

