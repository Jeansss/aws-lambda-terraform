const { CognitoIdentityProviderClient, AdminInitiateAuthCommand, AdminCreateUserCommand, AdminRespondToAuthChallengeCommand, ListUserPoolsCommand, ListUserPoolClientsCommand } = require("@aws-sdk/client-cognito-identity-provider");
const client = new CognitoIdentityProviderClient({ region: "us-east-1" });

exports.handler = async (event) => {
  try {
    const userPoolId = await getUserPoolId();
    const clientId = await getClientId(userPoolId);
    const cpf = event.cpf;
    const password = "Test@123";
    const newPassword = "Test@@@123";
    await createUser(userPoolId, cpf);
    const auth = await authUser(clientId, userPoolId, cpf, password);
    const respond = await respondChallenge(userPoolId, clientId, cpf, newPassword, auth.Session);
    const token = respond.AuthenticationResult.IdToken;
    
    return {
      statusCode: 200,
      body: {token}
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};

async function getUserPoolId() {
  const command = new ListUserPoolsCommand();
  try {
    const data = await client.send(command);
    return data.UserPools[0].Id;
  } catch (error) {
    throw new Error(`Error getting user pool ID: ${error.message}`);
  }
}

async function getClientId(userPoolId) {
  const params = { UserPoolId: userPoolId };
  const command = new ListUserPoolClientsCommand(params);
  try {
    const data = await client.send(command);
    return data.UserPoolClients[0].ClientId;
  } catch (error) {
    throw new Error(`Error getting client ID: ${error.message}`);
  }
}

async function createUser(userPoolId, cpf) {
  const params = {
    UserPoolId: userPoolId,
    Username: cpf,
    ForceAliasCreation: false,
    TemporaryPassword: "Test@123",
  };
  const command = new AdminCreateUserCommand(params);

  try {
    await client.send(command);
  } catch (error) {
    throw new Error(`Error creating user: ${error.message}`);
  }
}

async function respondChallenge(userPoolId, clientId, cpf, newPassword, session) {
  const params = {
    ChallengeName: "NEW_PASSWORD_REQUIRED",
    ClientId: clientId,
    UserPoolId: userPoolId,
    ChallengeResponses: {
      NEW_PASSWORD: newPassword,
      USERNAME: cpf,
    },
    Session: session
  };
  const command = new AdminRespondToAuthChallengeCommand(params);

  try {
    const data = await client.send(command);
    return data;
  } catch (error) {
    throw new Error(`Error responding to challenge: ${error.message}`);
  }
}

async function authUser(clientId, userPoolId, cpf, password) {
  const params = {
    AuthFlow: "ADMIN_NO_SRP_AUTH",
    ClientId: clientId,
    UserPoolId: userPoolId,
    AuthParameters: {
      USERNAME: cpf,
      PASSWORD: password,
    }
  };
  const command = new AdminInitiateAuthCommand(params);

  try {
    const data = await client.send(command);
    return data;
  } catch (error) {
    throw new Error(`Error authenticating user: ${error.message}`);
  }
}