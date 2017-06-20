from jira import JIRA, JIRAError
import argparse


parser = argparse.ArgumentParser(description='Verifies Jira Username and Password')


parser.add_argument('JiraHost', metavar='JiraHost', type=str, help='Jira Host full web address')
parser.add_argument('JiraUser', metavar='JiraUser', type=str, help='Jira UserName')
parser.add_argument('JiraPass', metavar='JiraPass', type=str, help='Jira Password')

parser.add_argument('--verbose', dest='VERBOSE', default=False, action='store_true', help='Add Verbose output')

if __name__ == "__main__":
   args=parser.parse_args()

   try:
      jira = JIRA(args.JiraHost, basic_auth=(args.JiraUser, args.JiraPass), max_retries=0)
   except JIRAError as e:
      if e.status_code == 401:
         print("Login to JIRA failed [%s]. Check your username [%s] and password [%s]" % (args.JiraHost, args.JiraUser, args.JiraPass))
         exit(1)
   exit(0)

