
```Javascript

const options = {
	authProvider,
};

const client = Client.init(options);

const String = {
  groupIds: [
    "groupIds-value"
  ]
};

let res = await client.api('/contacts/{id}/checkMemberGroups')
	.version('beta')
	.post(String);

```