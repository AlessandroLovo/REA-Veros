#### JSON IO #########
import json
import logging

if __name__ == '__main__':
    logger = logging.getLogger()
    logger.handlers = [logging.StreamHandler(sys.stdout)]
else:
    logger = logging.getLogger(__name__)
logger.level = logging.INFO

default_formatter = logging.Formatter('%(asctime)s %(message)s', datefmt='%m/%d/%Y %H:%M:%S')

#### JSON IO ####

def json2dict(filename):
    '''
    Reads a json file `filename` as a dictionary
    '''
    with open(filename, 'r') as j:
        d = json.load(j)
    return d

def dict2json(d, filename):
    '''
    Saves a dictionary `d` to a json file `filename`
    '''
    with open(filename, 'w') as j:
        json.dump(d, j, indent=4)
        
def dict2str(d, indent=4, **kwargs):
    '''
    A nice way of printing a nested dictionary
    '''
    return json.dumps(d, indent=indent, **kwargs)

#### TELEGRAM LOGGER ####

def new_telegram_handler(chat_ID=None, token=None, level=logging.WARNING, formatter=default_formatter, **kwargs):
    '''
    Creates a telegram handler object

    Parameters
    ----------
    chat_ID : int or str or None, optional
        chat ID of the telegram user or group to whom send the logs. If None it is the last used. If str it is a path to a file where it is stored.
        To find your chat ID go to telegram and search for 'userinfobot' and type '/start'. The bot will provide you with your chat ID.
        You can do the same with a telegram group, and, in this case, you will need to invite 'ENSMLbot' to the group.
        The default is None.
    token: str
        token for the telegram bot or path to a text file where the first line is the token
    level : int or logging.(NOTSET, DEBUG, INFO, WARNING, ERROR, CRITICAL), optional
        The default is logging.WARNING.
    formatter : logging.Formatter, str or None, optional
        The formatter used to log the messages. The default is default_formatter.
        If string it can be for example '%(levelname)s: %(message)s'
    **kwargs :
        additional arguments for telegram_handler.handlers.TelegramHandler

    Returns
    -------
    th: telegram_handler.handlers.TelegramHandler
        handler that logs to telegram
    '''
    import telegram_handler # NOTE: to install this package run pip install python-telegram-handler
    try:
        if token.startswith('~'):
            token = f"{os.environ['HOME']}{token[1:]}"
        with open(token, 'r') as token_file:
            token = token_file.readline().rstrip('\n')
    except FileNotFoundError:
        pass
    if isinstance(chat_ID, str) or isinstance(chat_ID, Path):
        with open(chat_ID, 'r') as chat_ID_file:
            chat_ID = int(chat_ID_file.readline().rstrip('\n'))
    th = telegram_handler.handlers.TelegramHandler(token=token, chat_id=chat_ID, **kwargs)
    if isinstance(formatter, str):
        if formatter == 'default':
            formatter = default_formatter
        else:
            formatter = logging.Formatter(formatter)
    if formatter is not None:
        th.setFormatter(formatter)
    th.setLevel(level)
    return th

