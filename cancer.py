
# coding: utf-8

# In[42]:


import pandas as pd
import numpy as np
from scipy import stats


# In[2]:


import matplotlib.pyplot as plt
import seaborn as sns
get_ipython().run_line_magic('matplotlib', 'inline')
sns.set_style('darkgrid')


# In[3]:


data = pd.read_csv('./Data/zpcd8615.dat', '\t', header=None)


# In[4]:


## There are 3 spaces between the first and second terms in the .dat file so I decide to split the data on 3 spaces
data = data[0].str.split('   ')


# In[5]:


data = pd.DataFrame(item for item in data)


# In[6]:


data.columns = ['X1', 'X2']


# In[7]:


data.drop('X2', axis=1, inplace=True)


# In[8]:


data['sex'] = data.X1.str[0]
data['years'] = data.X1.str[1]
data['zip'] = data.X1.str[2:7]
data['age'] = data.X1.str[10]
data['type'] = data.X1.str[8:10]
#data['stage'] = data.X1.str[7]


# In[9]:


data.drop('X1', axis=1, inplace=True)


# In[10]:


sexcode = {'1':'male', '2':'female'}
diagnosisyear = {'1':'1986-1990', '2':'1991-1995', '3':'1996-2000',
                 '4':'2001-2005', '5':'2006-2010', '6':'2011-2015'}
agegroup = {'1':'0-14', '2':'15-44', '3':'45-64', '4':'65+'}
cancertype = {' 1':'oral cavity and pharynx', ' 2':'colorectal', ' 3':'lung and bronchus',
              ' 4':'breast invasive-female', ' 5':'cervix', ' 6':'prostate',
              ' 7':'urinary system', ' 8':'central nervous system', ' 9':'lukemias and lymphomas',
              '10':'all other cancers', '11':'breast in-situ-female'}


# In[11]:


data['sex'].replace(sexcode, inplace=True)
data['years'].replace(diagnosisyear, inplace=True)
data['age'].replace(agegroup, inplace=True)
data['type'].replace(cancertype, inplace=True)


# In[12]:


data.head(10)


# In[13]:


sns.countplot(x='years', hue='age', hue_order= ['0-14', '15-44', '45-64', '65+'],
              data=data.sort_values(by='years'))
plt.legend(bbox_to_anchor=(1.05, .5), loc=2)


# In[14]:


data['years'].value_counts()


# In[15]:


data['sex'].value_counts()


# In[16]:


data['age'].value_counts()


# In[17]:


data['type'].value_counts()


# In[14]:


since2000 = ['2001-2005', '2006-2010', '2011-2015']


# In[15]:


datasub = data[(data['years'].isin(since2000))]


# In[20]:


datasub['age'].value_counts()


# In[16]:


zipcodes = ['60527', '60439', '60561', '60521', '60558', '60514',
            '60559', '60525', '60480', '60515', '60516', '60517']


# In[17]:


datalocal = data[data['zip'].isin(zipcodes)]


# In[18]:


datalocal['zip'].value_counts()


# In[19]:


sns.countplot(x='years', data=datalocal.sort_values(by='years'))


# In[20]:


datalocal['age'].value_counts()


# In[22]:


datalocalsub = datasub[datasub['zip'].isin(zipcodes)]


# In[24]:


datarestsub = datasub[-datasub['zip'].isin(zipcodes)]


# In[27]:


sns.countplot(x='years', data=datalocalsub.sort_values(by='years'))


# In[28]:


datalocalsub['age'].value_counts()


# In[29]:


datasub['age'].value_counts()


# In[30]:


sns.countplot(x='years', hue='age', data=datalocalsub.sort_values(by=['years', 'age']))
plt.legend(bbox_to_anchor=(1.05, .5), loc=2)


# In[25]:


pop_illinois = 12830632
num_cases = datasub.shape[0]
num_cases_per_year = num_cases/15
one_in_every_il = pop_illinois/num_cases_per_year
per_100000_il_per_year = num_cases_per_year * 100000 / pop_illinois


# In[26]:


one_in_every_il


# In[27]:


ilpop = pd.read_csv('./Data/il_2010_populations.csv', skiprows=1)
ilpop.drop(labels=['Id', 'Geography'], axis=1, inplace=True)
ilpop.rename(index=str, columns={'Id2':'zip', 'Total':'population'}, inplace=True)


# In[28]:


cancer_counts = datasub['zip'].value_counts()
ilcancer = cancer_counts.rename_axis('zip').reset_index(name='freq')
ilcancer['zip'] = pd.to_numeric(ilcancer['zip'])


# In[29]:


cancer = pd.merge(ilpop, ilcancer, 'left')
cancer['per year'] = cancer['freq']/15
cancer['one in every X per year'] = cancer['population']/cancer['per year']
cancer['per 100000 per year'] = cancer['per year']*100000/cancer['population']
cancer['zip vs state'] = cancer['per 100000 per year']/per_100000_il_per_year
cancer.head(6)


# In[31]:


cancer_local = cancer[cancer['zip'].isin(zipcodes)].sort_values('zip vs state', ascending=False)
cancer_local


# In[33]:


cancer_rest = cancer[-cancer['zip'].isin(zipcodes)]
cancer_rest.head()


# In[37]:


cancer_rest_big = cancer_rest[cancer_rest['population'] > 5000]
cancer_rest_big.head()


# In[42]:


sns.barplot(x='zip', y='per 100000 per year', data=cancer_local)
plt.axhline(y=per_100000_il_per_year, color='black', linewidth=3)
plt.text(7.5, per_100000_il_per_year-10, round(per_100000_il_per_year, 2))


# In[38]:


local_counts = datalocalsub.groupby(['years', 'zip'])
local_counts = local_counts.size().reset_index()
local_counts.rename(index = str, columns= {0:'n'}, inplace=True)


# In[39]:


illinois_counts = datasub.groupby('years')
illinois_counts = illinois_counts.size().reset_index()
illinois_counts['zip'] = ['Illinois', 'Illinois', 'Illinois']
illinois_counts.rename(index=str, columns={0:'n'}, inplace=True)
illinois_counts = illinois_counts[['years', 'zip', 'n']]


# In[40]:


counts = local_counts.append(illinois_counts)
counts


# In[41]:


g = sns.FacetGrid(counts, col='zip', col_wrap = 3, size=4, sharey = False)
g = g.map(plt.bar, 'years', 'n')


# In[96]:


t1, p1 = stats.ttest_ind(a=cancer_local['per 100000 per year'], b=cancer_rest_big['per 100000 per year'], equal_var=False)


# In[103]:


t1


# In[100]:


p1/2


# In[54]:


local_cancer = cancer_local['freq'].sum()/15
local_no_cancer = cancer_local['population'].sum()/15-local_cancer
rest_cancer = cancer_rest_big['freq'].sum()/15
rest_no_cancer = cancer_rest_big['population'].sum()/15-rest_cancer


# In[106]:


cont=[[local_cancer, local_no_cancer], [rest_cancer, rest_no_cancer]]
cont = pd.DataFrame(cont)
cont = cont.round(0)
cont.columns = ['Cancer', 'No Cancer']
cont.index = ['Sterigenics Area', 'Rest of State']
cont


# In[107]:


chi2, p, dof, ex = stats.chi2_contingency(cont, correction = False)


# In[108]:


chi2


# In[109]:


p


# In[110]:


dof


# In[111]:


ex

