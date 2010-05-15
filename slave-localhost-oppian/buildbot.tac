
from twisted.application import service
from buildbot.slave.bot import BuildSlave
import os.path

basedir = os.path.abspath(os.path.dirname(__file__))
buildmaster_host = 'localhost'
port = 9990
slavename = 'localhost'
passwd = 'lesty27'
keepalive = 600
usepty = 0
umask = 022
maxdelay = 300
rotateLength = 1000000
maxRotatedFiles = None

application = service.Application('buildslave')
try:
  from twisted.python.logfile import LogFile
  from twisted.python.log import ILogObserver, FileLogObserver
  logfile = LogFile.fromFullPath("twistd.log", rotateLength=rotateLength,
                                 maxRotatedFiles=maxRotatedFiles)
  application.setComponent(ILogObserver, FileLogObserver(logfile).emit)
except ImportError:
  # probably not yet twisted 8.2.0 and beyond, can't set log yet
  pass
s = BuildSlave(buildmaster_host, port, slavename, passwd, basedir,
               keepalive, usepty, umask=umask, maxdelay=maxdelay)
s.setServiceParent(application)

