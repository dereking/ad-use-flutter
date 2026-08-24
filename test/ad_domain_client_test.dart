import 'package:ad_use_flutter/ad_use_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

final _users = const [
  AdDomainUser(
    distinguishedName:
        'CN=Alice Zhang,OU=Engineering,OU=Shanghai,DC=example,DC=com',
    username: 'alice.zhang',
    userPrincipalName: 'alice.zhang@example.com',
    email: 'alice@example.com',
    displayName: 'Alice Zhang',
    commonName: 'Alice Zhang',
    department: 'Engineering',
    title: 'Engineer',
  ),
  AdDomainUser(
    distinguishedName: 'CN=Bob Li,OU=Sales,DC=example,DC=com',
    username: 'bob.li',
    userPrincipalName: 'bob.li@example.com',
    email: 'bob@example.com',
    displayName: 'Bob Li',
    commonName: 'Bob Li',
    department: 'Sales',
    title: 'Salesperson',
  ),
];

void main() {
  group('AdDomainClient', () {
    test('gets user details by email and caches all returned indexes',
        () async {
      final adapter = FakeAdDomainDirectoryAdapter(
        users: [
          const AdDomainUser(
            distinguishedName:
                'CN=Alice Zhang,OU=Engineering,OU=Shanghai,DC=example,DC=com',
            username: 'alice.zhang',
            email: 'alice@example.com',
            displayName: 'Alice Zhang',
            commonName: 'Alice Zhang',
            department: 'Engineering',
            title: 'Engineer',
          ),
        ],
      );
      final client = AdDomainClient(
        config: const AdDomainConfig(
          host: 'ad.example.com',
          bindDn: 'CN=svc,DC=example,DC=com',
          bindPassword: 'secret',
          baseDn: 'DC=example,DC=com',
        ),
        adapter: adapter,
      );

      final byEmail = await client.getUserByEmail('alice@example.com');
      final byUsername = await client.getUserByUsername('alice.zhang');

      expect(byEmail?.displayName, 'Alice Zhang');
      expect(byUsername?.email, 'alice@example.com');
      expect(adapter.emailLookupCount, 1);
      expect(adapter.usernameLookupCount, 0);
    });

    test('searches users by name and returns cached email details', () async {
      final adapter = FakeAdDomainDirectoryAdapter(
        users: [
          const AdDomainUser(
            distinguishedName: 'CN=Bob Li,OU=Sales,DC=example,DC=com',
            username: 'bob.li',
            email: 'bob@example.com',
            displayName: 'Bob Li',
            commonName: 'Bob Li',
            department: 'Sales',
          ),
        ],
      );
      final client = AdDomainClient(
        config: const AdDomainConfig(
          host: 'ad.example.com',
          bindDn: 'CN=svc,DC=example,DC=com',
          bindPassword: 'secret',
          baseDn: 'DC=example,DC=com',
        ),
        adapter: adapter,
      );

      final matches = await client.searchUsersByName('Bob');
      final byEmail = await client.getUserByEmail('bob@example.com');

      expect(matches.map((user) => user.email), ['bob@example.com']);
      expect(byEmail?.username, 'bob.li');
      expect(adapter.nameSearchCount, 1);
      expect(adapter.emailLookupCount, 0);
    });

    test('queries users by email-address prefix (domain username)', () async {
      final adapter = FakeAdDomainDirectoryAdapter(
        users: _users,
      );
      final client = AdDomainClient(
        config: const AdDomainConfig(
          host: 'ad.example.com',
          bindDn: 'CN=svc,DC=example,DC=com',
          bindPassword: 'secret',
          baseDn: 'DC=example,DC=com',
        ),
        adapter: adapter,
      );

      final byPrefix = await client.searchUsersByEmailPrefix('alice');
      final byEmail = await client.getUserByEmail('alice@example.com');

      expect(byPrefix.map((user) => user.email), ['alice@example.com']);
      expect(byPrefix.single.department, 'Engineering');
      expect(byPrefix.single.title, 'Engineer');
      expect(byEmail?.username, 'alice.zhang');
    });

    test('queries users by display name', () async {
      final adapter = FakeAdDomainDirectoryAdapter(
        users: _users,
      );
      final client = AdDomainClient(
        config: const AdDomainConfig(
          host: 'ad.example.com',
          bindDn: 'CN=svc,DC=example,DC=com',
          bindPassword: 'secret',
          baseDn: 'DC=example,DC=com',
        ),
        adapter: adapter,
      );

      final matches = await client.searchUsersByDisplayName('alice zhang');

      expect(matches.map((user) => user.email), ['alice@example.com']);
    });

    test('queries users by domain username prefix', () async {
      final adapter = FakeAdDomainDirectoryAdapter(
        users: _users,
      );
      final client = AdDomainClient(
        config: const AdDomainConfig(
          host: 'ad.example.com',
          bindDn: 'CN=svc,DC=example,DC=com',
          bindPassword: 'secret',
          baseDn: 'DC=example,DC=com',
        ),
        adapter: adapter,
      );

      final matches = await client.searchUsersByUsernamePrefix('alice.zh');
      expect(matches.map((user) => user.email), ['alice@example.com']);
    });

    test('returns empty for blank email-prefix and display-name queries',
        () async {
      final adapter = FakeAdDomainDirectoryAdapter(users: _users);
      final client = AdDomainClient(
        config: const AdDomainConfig(
          host: 'ad.example.com',
          bindDn: 'CN=svc,DC=example,DC=com',
          bindPassword: 'secret',
          baseDn: 'DC=example,DC=com',
        ),
        adapter: adapter,
      );

      expect(await client.searchUsersByEmailPrefix(''), isEmpty);
      expect(await client.searchUsersByDisplayName('   '), isEmpty);
      expect(await client.searchUsersByUsernamePrefix(''), isEmpty);
    });

    test('builds and caches organization tree from user distinguished names',
        () async {
      final adapter = FakeAdDomainDirectoryAdapter(
        users: [
          const AdDomainUser(
            distinguishedName:
                'CN=Alice Zhang,OU=Platform,OU=Engineering,DC=example,DC=com',
            username: 'alice.zhang',
            email: 'alice@example.com',
            displayName: 'Alice Zhang',
          ),
          const AdDomainUser(
            distinguishedName: 'CN=Bob Li,OU=Sales,DC=example,DC=com',
            username: 'bob.li',
            email: 'bob@example.com',
            displayName: 'Bob Li',
          ),
        ],
      );
      final client = AdDomainClient(
        config: const AdDomainConfig(
          host: 'ad.example.com',
          bindDn: 'CN=svc,DC=example,DC=com',
          bindPassword: 'secret',
          baseDn: 'DC=example,DC=com',
          organizationTreeMode: AdOrganizationTreeMode.ou,
        ),
        adapter: adapter,
      );

      final first = await client.getOrganizationTree();
      final second = await client.getOrganizationTree();

      expect(first.map((node) => node.name), ['Engineering', 'Sales']);
      expect(first.first.children.map((node) => node.name), ['Platform']);
      expect(first.first.children.single.users.map((user) => user.email),
          ['alice@example.com']);
      expect(second, first);
      expect(adapter.allUsersLookupCount, 1);
    });

    test('can build organization tree from department values', () async {
      final adapter = FakeAdDomainDirectoryAdapter(
        users: [
          const AdDomainUser(
            distinguishedName: 'CN=Alice Zhang,DC=example,DC=com',
            username: 'alice.zhang',
            email: 'alice@example.com',
            displayName: 'Alice Zhang',
            department: 'Engineering/Platform',
          ),
        ],
      );
      final client = AdDomainClient(
        config: const AdDomainConfig(
          host: 'ad.example.com',
          bindDn: 'CN=svc,DC=example,DC=com',
          bindPassword: 'secret',
          baseDn: 'DC=example,DC=com',
          organizationTreeMode: AdOrganizationTreeMode.department,
        ),
        adapter: adapter,
      );

      final tree = await client.getOrganizationTree();

      expect(tree.map((node) => node.name), ['Engineering']);
      expect(tree.single.children.map((node) => node.name), ['Platform']);
      expect(
          tree.single.children.single.users.single.email, 'alice@example.com');
    });

    test('warmUpCache stores all user data and organization tree', () async {
      final adapter = FakeAdDomainDirectoryAdapter(
        users: [
          const AdDomainUser(
            distinguishedName: 'CN=Carol Wu,OU=HR,DC=example,DC=com',
            username: 'carol.wu',
            email: 'carol@example.com',
            displayName: 'Carol Wu',
          ),
        ],
      );
      final client = AdDomainClient(
        config: const AdDomainConfig(
          host: 'ad.example.com',
          bindDn: 'CN=svc,DC=example,DC=com',
          bindPassword: 'secret',
          baseDn: 'DC=example,DC=com',
        ),
        adapter: adapter,
      );

      await client.warmUpCache();
      final byEmail = await client.getUserByEmail('carol@example.com');
      final tree = await client.getOrganizationTree();

      expect(byEmail?.displayName, 'Carol Wu');
      expect(tree.single.name, 'HR');
      expect(adapter.allUsersLookupCount, 1);
      expect(adapter.emailLookupCount, 0);
    });

    test('clearCache forces the next lookup to query the adapter', () async {
      final adapter = FakeAdDomainDirectoryAdapter(
        users: [
          const AdDomainUser(
            distinguishedName: 'CN=Dan,DC=example,DC=com',
            username: 'dan',
            email: 'dan@example.com',
            displayName: 'Dan',
          ),
        ],
      );
      final client = AdDomainClient(
        config: const AdDomainConfig(
          host: 'ad.example.com',
          bindDn: 'CN=svc,DC=example,DC=com',
          bindPassword: 'secret',
          baseDn: 'DC=example,DC=com',
        ),
        adapter: adapter,
      );

      await client.getUserByEmail('dan@example.com');
      await client.clearCache();
      await client.getUserByEmail('dan@example.com');

      expect(adapter.emailLookupCount, 2);
    });
  });
}

class FakeAdDomainDirectoryAdapter implements AdDomainDirectoryAdapter {
  FakeAdDomainDirectoryAdapter({required List<AdDomainUser> users})
      : _users = users;

  final List<AdDomainUser> _users;
  int emailLookupCount = 0;
  int usernameLookupCount = 0;
  int nameSearchCount = 0;
  int allUsersLookupCount = 0;

  @override
  Future<bool> authenticate(String username, String password) async => true;

  @override
  Future<AdDomainUser?> getUserByEmail(String email) async {
    emailLookupCount++;
    return _users.where((user) => user.email == email).firstOrNull;
  }

  @override
  Future<AdDomainUser?> getUserByUsername(String username) async {
    usernameLookupCount++;
    return _users.where((user) => user.username == username).firstOrNull;
  }

  @override
  Future<List<AdDomainUser>> searchUsersByName(String name) async {
    nameSearchCount++;
    final normalized = name.toLowerCase();
    return _users
        .where((user) => user.displayName.toLowerCase().contains(normalized))
        .toList();
  }

  @override
  Future<List<AdDomainUser>> searchUsersByEmailPrefix(
      String emailPrefix) async {
    final normalized = emailPrefix.toLowerCase();
    return _users
        .where((user) =>
            user.email.toLowerCase().startsWith(normalized) ||
            (user.username.toLowerCase().startsWith(normalized)))
        .toList();
  }

  @override
  Future<List<AdDomainUser>> searchUsersByDisplayName(String name) async {
    final normalized = name.toLowerCase();
    return _users
        .where((user) => user.displayName.toLowerCase().contains(normalized))
        .toList();
  }

  @override
  Future<List<AdDomainUser>> searchUsersByUsernamePrefix(
      String usernamePrefix) async {
    final normalized = usernamePrefix.toLowerCase();
    return _users
        .where((user) =>
            user.username.toLowerCase().startsWith(normalized) ||
            (user.userPrincipalName?.toLowerCase().startsWith(normalized) ??
                false))
        .toList();
  }

  @override
  Future<List<AdDomainUser>> getAllUsers() async {
    allUsersLookupCount++;
    return _users;
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => this.isEmpty ? null : first;
}
