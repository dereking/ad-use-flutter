# ad-use-flutter

Flutter-compatible LDAP and Active Directory wrapper for Glink apps.

The Dart package name is `ad_use_flutter` because pub package names cannot use
hyphens.

## Features

- Authenticate an AD user by password.
- Resolve user details by email.
- Resolve user details by username or UPN.
- Search users by display name or common name.
- Build an organization tree from OU paths or department values.
- Cache all user lookup and organization tree data in memory with TTL.

## Example

```dart
final client = AdDomainClient(
  config: AdDomainConfig(
    host: 'ad.example.com',
    useSsl: true,
    port: 636,
    bindDn: 'CN=svc-glink,OU=Service Accounts,DC=example,DC=com',
    bindPassword: 'secret',
    baseDn: 'DC=example,DC=com',
  ),
);

final user = await client.getUserByEmail('alice@example.com');
final matches = await client.searchUsersByName('Alice');
final tree = await client.getOrganizationTree();
```
