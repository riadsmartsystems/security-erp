"""E9: PITR drill tests — верифікація що binlog та backup ready для point-in-time recovery."""
import os
import unittest


class TestBinlogConfig(unittest.TestCase):
    """Перевіряє configs/mariadb.cnf."""

    def test_mariadb_cnfd_has_binlog(self):
        cnf_path = os.path.join(os.path.dirname(__file__), '..', '..', 'configs', 'mariadb.cnf')
        if not os.path.exists(cnf_path):
            self.skipTest(f"mariadb.cnf not found at {cnf_path}")
        content = open(cnf_path).read()
        self.assertIn('log_bin', content, "mariadb.cnf must have log_bin")
        self.assertNotIn('log_bin = OFF', content, "log_bin must not be OFF")

    def test_binlog_format_is_row(self):
        cnf_path = os.path.join(os.path.dirname(__file__), '..', '..', 'configs', 'mariadb.cnf')
        if not os.path.exists(cnf_path):
            self.skipTest("mariadb.cnf not found")
        content = open(cnf_path).read()
        self.assertIn('binlog_format', content, "mariadb.cnf must have binlog_format")
        self.assertIn('ROW', content.upper(), "binlog_format must be ROW")


class TestBackupScript(unittest.TestCase):
    """Перевіряє scripts/backup-mariadb.sh."""

    def test_backup_script_has_master_data(self):
        script_path = os.path.join(os.path.dirname(__file__), '..', '..', 'scripts', 'backup-mariadb.sh')
        if not os.path.exists(script_path):
            self.skipTest("backup-mariadb.sh not found")
        content = open(script_path).read()
        self.assertIn('--master-data', content, "backup script must use --master-data")

    def test_backup_script_has_gpg(self):
        script_path = os.path.join(os.path.dirname(__file__), '..', '..', 'scripts', 'backup-mariadb.sh')
        if not os.path.exists(script_path):
            self.skipTest("backup-mariadb.sh not found")
        content = open(script_path).read()
        self.assertIn('gpg', content, "backup script must use GPG encryption")


class TestRedisAOF(unittest.TestCase):
    """Перевіряє configs/redis.conf."""

    def test_redis_conf_has_aof(self):
        conf_path = os.path.join(os.path.dirname(__file__), '..', '..', 'configs', 'redis.conf')
        if not os.path.exists(conf_path):
            self.skipTest("redis.conf not found")
        content = open(conf_path).read()
        self.assertIn('appendonly yes', content, "redis.conf must have appendonly yes")


if __name__ == "__main__":
    unittest.main()
