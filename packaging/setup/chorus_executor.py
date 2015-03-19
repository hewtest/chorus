import os
import subprocess
import shlex
from log import logger
from options import get_version
class PSQLException(Exception):
    pass

class RAKEException(Exception):
    pass

class ChorusExecutor:
    def __init__(self, chorus_path="/usr/local/chorus"):
        self.chorus_path = chorus_path
        self.release_path = os.path.join(chorus_path, 'releases/%s' % get_version(chorus_path))

    def call(self, command):
        logger.debug(command)
        return subprocess.call(shlex.split(command))

    def run(self, command, postgres_bin_path=None):
        if postgres_bin_path is None:
            postgres_bin_path = self.release_path
        command = "PATH=%s/postgres/bin:$PATH && %s" % (postgres_bin_path, command)
        logger.debug(command)
        p = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = p.communicate()
        if stdout:
            logger.debug(stdout)
        if stderr:
            logger.debug(stderr)
        return stdout, stderr

    def extract_postgres(self, package_name):
        self.run("tar xzfv %s -C %s" % (os.path.join(self.release_path, "packaging/postgres/" + package_name),\
                                        self.release_path))

    def chorus_control(self, command):
       command = "CHORUS_HOME=%s %s %s/packaging/chorus_control.sh %s" % \
               (self.release_path, self.alpine_env(), self.release_path, command)
       return self.run(command)

    def previous_chorus_control(self, command):
        command = "CHORUS_HOME=%s %s %s %s" % \
                (os.path.join(self.chorus_path, "current"), self.alpine_env(),\
                os.path.join(self.chorus_path, "chorus_control.sh"), command)
        self.run(command, os.path.join(self.chorus_path, "current"))

    def alpine_env(self):
        return "ALPINE_HOME=%s/alpine-current ALPINE_DATA_REPOSITORY=%s/shared/ALPINE_DATA_REPOSITORY" % \
                (self.chorus_path, self.chorus_path)

    def start_previous_release(self):
        self.previous_chorus_control("start")

    def stop_previous_release(self):
        self.previous_chorus_control("stop")
        #self.run("killall chorus")
    def start_postgres(self):
        logger.info("Starting postgres...")
        stdout, stderr = self.chorus_control("start postgres")
        if "postgres failed" in stdout:
            raise PSQLException(stdout)

    def stop_postgres(self):
        logger.info("Stopping postgres")
        stdout, stderr = self.chorus_control("stop postgres")
        if "postgres failed" in stdout:
            raise PSQLException(stdout)

    def initdb(self, data_path, database_user):
        command = "initdb --locale=en_US.UTF-8 -D %s/db --auth=md5 --pwfile=%s/postgres/pwfile --username=%s" % \
                (data_path, self.release_path, database_user)
        stdout, stderr = self.run(command)
        if "exists but is not empty" in stderr:
            logger.warning(stderr)

    def rake(self, command):
        command = "cd %s && RAILS_ENV=production bin/ruby -S bin/rake %s --trace" % \
                (self.release_path, command)
        stdout, stderr = self.run(command)
        if "rake aborted" in stderr:
            raise RAKEException(stderr)
